import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';
import 'package:odlikas_mobilna/database/models/tests.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';
import 'package:odlikas_mobilna/services/openAiService.dart';

class AIAssistantService {
  final ApiService _apiService;
  final OpenAIService _openAIService;

  // Cache API data to minimize redundant calls
  StudentProfile? _cachedProfile;
  Grades? _cachedGrades;
  Tests? _cachedTests;
  ScheduleSubject? _cachedSchedule;

  // Singleton instance
  static final AIAssistantService _instance = AIAssistantService._internal();

  factory AIAssistantService() {
    return _instance;
  }

  AIAssistantService._internal()
      : _apiService = ApiService(),
        _openAIService = OpenAIService();

  // Get credentials from Hive box
  Map<String, String> _getCredentials() {
    final userBox = Hive.box('User');
    final email = userBox.get('email') as String?;
    final password = userBox.get('password') as String?;

    return {
      'email': email ?? '',
      'password': password ?? '',
    };
  }

  // Check if credentials are available
  bool get hasCredentials {
    final credentials = _getCredentials();
    return credentials['email']!.isNotEmpty &&
        credentials['password']!.isNotEmpty;
  }

  // Clear all cached data (useful for logout)
  void clearCache() {
    _cachedProfile = null;
    _cachedGrades = null;
    _cachedTests = null;
    _cachedSchedule = null;
  }

  // Process a query from the user and provide an intelligent response
  Future<String> processQuery(String query) async {
    if (!hasCredentials) {
      return "Molimo prvo se prijavite kako biste koristili AI asistenta.";
    }

    try {
      // Normalize the query by converting to lowercase for easier matching
      final normalizedQuery = query.toLowerCase();

      // Extract intent from query using more sophisticated keyword matching and context
      if (_isAboutTests(normalizedQuery)) {
        return await _getTestInfo(normalizedQuery);
      } else if (_isAboutGrades(normalizedQuery)) {
        return await _getGradesInfo(normalizedQuery);
      } else if (_isAboutSchedule(normalizedQuery)) {
        return await _getScheduleInfo(normalizedQuery);
      } else if (_isAboutProfile(normalizedQuery)) {
        return await _getProfileInfo();
      } else {
        // For queries we can't directly map to our APIs, use OpenAI
        return await _getOpenAIResponse(query);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in processQuery: $e');
        print(e.runtimeType);
        if (e is Error) {
          print(e.stackTrace);
        }
      }
      return "Oprostite, dogodila se pogreška prilikom obrade vašeg zahtjeva: ${e.toString()}";
    }
  }

  // INTENT DETECTION HELPERS - IMPROVED WITH MORE CONTEXT AWARENESS

  bool _isAboutTests(String query) {
    final testKeywords = [
      'sljedeći test',
      'nadolazeći test',
      'raspored testova',
      'kada imam test',
      'budući test',
      'datum ispita',
      'kada ću imati test',
      'kalendar testova',
      'ispit',
      'kontrolni',
      'provjera',
      'test',
      'pismeni',
      'usmeni',
      // Added more specificity for finding particular tests
      'drugi test',
      'treći test',
      'idući test',
      'last test',
      'sljedeći',
      'dolazi',
      'nadolazeće',
      'drugi',
      'treći',
      'četvrti',
      'povijest testova',
      'svi testovi'
    ];

    return testKeywords.any((keyword) => query.contains(keyword));
  }

  bool _isAboutGrades(String query) {
    final gradeKeywords = [
      'ocjena',
      'ocjene',
      'prosjek',
      'kako mi ide',
      'uspjeh',
      'ocjena iz predmeta',
      'zaključna ocjena',
      'prolaz',
      'prolazim li',
      'kakve su mi ocjene',
      'koliko imam iz',
      'ocjenjivanje',
      // Added more patterns
      'sve ocjene',
      'najbolja ocjena',
      'najlošija ocjena',
      'zadnja ocjena',
      'najnovija ocjena',
      'prosječna ocjena',
      'moje ocjene'
    ];
    return gradeKeywords.any((keyword) => query.contains(keyword));
  }

  bool _isAboutSchedule(String query) {
    final scheduleKeywords = [
      'raspored',
      'raspored sati',
      'vrijeme nastave',
      'kada imam',
      'predavanja',
      'današnji satovi',
      'sutrašnji sat',
      'raspored za ponedjeljak',
      'raspored za utorak',
      'raspored za srijedu',
      'raspored za četvrtak',
      'raspored za petak',
      'satnica',
      'predmeti',
      'nastava',
      'sat',
      'kada',
      'danas',
      'sutra',
      // Additional keywords
      'tjedni raspored',
      'ovotjedni raspored',
      'sljedeći tjedan'
    ];
    return scheduleKeywords.any((keyword) => query.contains(keyword));
  }

  bool _isAboutProfile(String query) {
    final profileKeywords = [
      'moj profil',
      'tko sam ja',
      'informacije o učeniku',
      'moji podaci',
      'osobni podaci',
      'o meni',
      'moje ime',
      'moj razred',
      'moj program',
      'škola',
      'razrednik',
      'razred',
      'smjer',
      'osobne informacije',
      'detalji profila'
    ];
    return profileKeywords.any((keyword) => query.contains(keyword));
  }

  // DATA FETCHING HELPERS

  Future<StudentProfile> _getProfile() async {
    if (_cachedProfile != null) {
      return _cachedProfile!;
    }

    _cachedProfile = await _apiService.fetchStudentProfile();
    return _cachedProfile!;
  }

  Future<Grades> _getGrades() async {
    if (_cachedGrades != null) {
      return _cachedGrades!;
    }

    _cachedGrades = await _apiService.fetchGrades();
    return _cachedGrades!;
  }

  Future<Tests> _getTests() async {
    if (_cachedTests != null) {
      return _cachedTests!;
    }

    _cachedTests = await _apiService.fetchTestsDetails();
    return _cachedTests!;
  }

  Future<ScheduleSubject> _getSchedule() async {
    if (_cachedSchedule != null) {
      return _cachedSchedule!;
    }

    _cachedSchedule = await _apiService.fetchScheduleSubjects();
    return _cachedSchedule!;
  }

  // RESPONSE GENERATORS - COMPLETELY REFACTORED

  // Improved test info function that can handle specific test queries
  Future<String> _getTestInfo(String query) async {
    try {
      final tests = await _getTests();

      // Debug output of test data
      if (kDebugMode) {
        print('Retrieved ${tests.testsByMonth.length} months of test data');
        print('Total months: ${tests.testsByMonth.keys.join(', ')}');

        int totalTests = 0;
        for (final entry in tests.testsByMonth.entries) {
          totalTests += entry.value.length;
          print('Month ${entry.key}: ${entry.value.length} tests');

          for (int i = 0; i < min(2, entry.value.length); i++) {
            final test = entry.value[i];
            print(
                'Test example: Name="${test.testName}", Date="${test.testDate}", Desc="${test.testDescription}"');
          }
        }
        print('Total tests found: $totalTests');
      }

      // Get current date for comparison
      final now = DateTime.now();

      // Process all tests into a single flat list for easier handling
      List<TestDetail> allTests = [];
      for (final entry in tests.testsByMonth.entries) {
        allTests.addAll(entry.value);
      }

      if (allTests.isEmpty) {
        return "Nema dostupnih podataka o testovima.";
      }

      // Check if query is about all tests
      if (query.contains('svi testovi') ||
          query.contains('sve testove') ||
          query.contains('popis testova') ||
          query.contains('svih testova')) {
        return _getAllTestsInfo(allTests);
      }

      // Check if query is about a specific test (by ordinal number)
      if (query.contains('prvi') ||
          query.contains('drugi') ||
          query.contains('treći') ||
          query.contains('četvrti') ||
          query.contains('peti') ||
          query.contains('idući')) {
        // Sort tests by date
        final sortedTests = _getSortedTests(allTests);

        if (sortedTests.isEmpty) {
          return "Nema dostupnih testova s ispravnim datumima.";
        }

        // Determine which test the user is asking about
        int testIndex = -1;
        if (query.contains('prvi'))
          testIndex = 0;
        else if (query.contains('drugi'))
          testIndex = 1;
        else if (query.contains('treći'))
          testIndex = 2;
        else if (query.contains('četvrti'))
          testIndex = 3;
        else if (query.contains('peti'))
          testIndex = 4;
        else if (query.contains('idući') || query.contains('sljedeći')) {
          // Find the next upcoming test
          for (int i = 0; i < sortedTests.length; i++) {
            try {
              final testDate = _parseTestDate(sortedTests[i].testDate);
              if (testDate.isAfter(now)) {
                testIndex = i;
                break;
              }
            } catch (e) {
              // Skip tests with invalid dates
              if (kDebugMode) {
                print(
                    'Error parsing test date: "${sortedTests[i].testDate}", Error: $e');
              }
            }
          }
        }

        // If we found a valid index, return that specific test
        if (testIndex >= 0 && testIndex < sortedTests.length) {
          return _formatTestDetail(sortedTests[testIndex], now);
        } else if (query.contains('idući') || query.contains('sljedeći')) {
          return "Nema nadolazećih testova u rasporedu.";
        } else {
          return "Ne mogu pronaći traženi test. Ukupno ima ${sortedTests.length} testova.";
        }
      }

      // Check if query is about a specific subject
      for (final test in allTests) {
        if (query.contains(test.testName.toLowerCase())) {
          return _formatTestDetail(test, now);
        }
      }

      // Default: Return next upcoming test
      final sortedFutureTests = _getSortedTests(allTests).where((test) {
        try {
          final testDate = _parseTestDate(test.testDate);
          return testDate.isAfter(now);
        } catch (e) {
          return false;
        }
      }).toList();

      if (sortedFutureTests.isNotEmpty) {
        return _formatTestDetail(sortedFutureTests.first, now);
      } else {
        return "Dobre vijesti! Nemaš zakazanih nadolazećih testova.";
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _getTestInfo: $e');
        if (e is Error) {
          print(e.stackTrace);
        }
      }
      return "Žao mi je, došlo je do pogreške pri dohvaćanju informacija o testovima. Molimo pokušajte ponovno kasnije. (${e.toString()})";
    }
  }

  // Helper to get all tests sorted by date
  List<TestDetail> _getSortedTests(List<TestDetail> tests) {
    final now = DateTime.now();
    final List<MapEntry<TestDetail, DateTime>> testsWithDates = [];

    for (final test in tests) {
      try {
        if (test.testDate.isNotEmpty) {
          final date = _parseTestDate(test.testDate);
          testsWithDates.add(MapEntry(test, date));
        }
      } catch (e) {
        // Skip tests with invalid dates
        if (kDebugMode) {
          print('Error parsing test date: "${test.testDate}", Error: $e');
        }
      }
    }

    // Sort by date
    testsWithDates.sort((a, b) => a.value.compareTo(b.value));

    // Return just the tests
    return testsWithDates.map((e) => e.key).toList();
  }

  // Format all tests into a single response
  String _getAllTestsInfo(List<TestDetail> allTests) {
    final now = DateTime.now();
    final sortedTests = _getSortedTests(allTests);

    if (sortedTests.isEmpty) {
      return "Nema dostupnih testova u sustavu.";
    }

    // Split into past and future tests
    final pastTests = <TestDetail>[];
    final futureTests = <TestDetail>[];

    for (final test in sortedTests) {
      try {
        final testDate = _parseTestDate(test.testDate);
        if (testDate.isBefore(now)) {
          pastTests.add(test);
        } else {
          futureTests.add(test);
        }
      } catch (e) {
        // Skip tests with invalid dates
        if (kDebugMode) {
          print('Error categorizing test: "${test.testDate}", Error: $e');
        }
      }
    }

    // Build the response
    String response = "Pregled svih testova:\n\n";

    if (futureTests.isNotEmpty) {
      response += "Nadolazeći testovi (${futureTests.length}):\n";
      for (int i = 0; i < futureTests.length; i++) {
        final test = futureTests[i];
        final daysUntil = _getDaysUntilTest(test.testDate, now);
        final testName = test.testName;
        response += "${i + 1}. $testName (${test.testDate})";
        if (daysUntil != null) {
          if (daysUntil == 0) {
            response += " - danas";
          } else if (daysUntil == 1) {
            response += " - sutra";
          } else {
            response += " - za $daysUntil dana";
          }
        }
        response += "\n";
      }
      response += "\n";
    } else {
      response += "Nemaš nadolazećih testova.\n\n";
    }

    if (pastTests.isNotEmpty) {
      // Show the most recent past tests first
      final recentPastTests = pastTests.reversed.take(5).toList();
      response += "Nedavni testovi (${recentPastTests.length}):\n";
      for (int i = 0; i < recentPastTests.length; i++) {
        final test = recentPastTests[i];
        final testName = test.testName;
        response += "${i + 1}. $testName (${test.testDate})\n";
      }
    }

    return response;
  }

  // Format a single test detail into a response
  String _formatTestDetail(TestDetail test, DateTime now) {
    final daysUntil = _getDaysUntilTest(test.testDate, now);
    String timeDescription = "";

    if (daysUntil != null) {
      if (daysUntil == 0) {
        timeDescription = "danas";
      } else if (daysUntil == 1) {
        timeDescription = "sutra";
      } else if (daysUntil > 0) {
        timeDescription = "za $daysUntil dana";
      } else {
        timeDescription = "prije ${-daysUntil} dana";
      }
    }

    final testName = test.testName;
    String response =
        "Test \"$testName\" zakazan za ${test.testDate} ($timeDescription).";

    if (test.testDescription.isNotEmpty) {
      response += "\nDetalji: ${test.testDescription}";
    }

    return response;
  }

  // Helper to calculate days until a test
  int? _getDaysUntilTest(String testDateStr, DateTime now) {
    try {
      final testDate = _parseTestDate(testDateStr);
      // Get just the date part (ignore time)
      final todayDate = DateTime(now.year, now.month, now.day);
      final testDateOnly =
          DateTime(testDate.year, testDate.month, testDate.day);
      return testDateOnly.difference(todayDate).inDays;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating days until test: "$testDateStr", Error: $e');
      }
      return null;
    }
  }

  // Completely refactored grades function to handle more complex queries
  Future<String> _getGradesInfo(String query) async {
    try {
      final grades = await _getGrades();

      if (kDebugMode) {
        print('Retrieved ${grades.subjects.length} subjects from grades data');
        // Print all subjects for debugging
        for (final subject in grades.subjects) {
          print(
              'Subject: ${subject.subjectName}, Grade: ${subject.grade}, Professor: ${subject.professor}, ID: ${subject.subjectId}');
        }
      }

      // Check if grades data is empty
      if (grades.subjects.isEmpty) {
        return "Nema dostupnih podataka o ocjenama. Molimo pokušajte kasnije.";
      }

      // Check if the query is about a specific subject
      String? specificSubject;
      String? subjectId;

      for (final subject in grades.subjects) {
        if (query.contains(subject.subjectName.toLowerCase())) {
          specificSubject = subject.subjectName;
          subjectId = subject.subjectId;
          break;
        }
      }

      // Handle query for a specific subject
      if (specificSubject != null) {
        try {
          final subject = grades.subjects.firstWhere(
            (s) => s.subjectName == specificSubject,
          );

          return "Tvoja trenutna ocjena iz predmeta $specificSubject je ${subject.grade}. "
              "Ovaj predmet predaje ${subject.professor}.";
        } catch (e) {
          if (kDebugMode) {
            print('Error finding subject: $e');
          }
          return "Nisam mogao pronaći detalje o predmetu $specificSubject.";
        }
      }

      // Check for highest/lowest grade queries
      if (query.contains('najbolja') || query.contains('najviša')) {
        return _getBestGradeInfo(grades);
      } else if (query.contains('najlošija') || query.contains('najniža')) {
        return _getWorstGradeInfo(grades);
      } else if (query.contains('prosjek') || query.contains('prosječna')) {
        return _getAverageGradeInfo(grades);
      } else if (query.contains('sve ocjene') ||
          query.contains('popis ocjena')) {
        return _getAllGradesInfo(grades);
      } else {
        // General grade summary
        return _getGradesSummary(grades);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _getGradesInfo: $e');
      }
      return "Došlo je do pogreške prilikom dohvaćanja podataka o ocjenama: ${e.toString()}";
    }
  }

  // Get the best grade info with improved grade format handling
  String _getBestGradeInfo(Grades grades) {
    final gradedSubjects = grades.subjects.where((s) {
      if (s.grade == 'N/A' || s.grade.isEmpty || s.grade == '-') {
        return false;
      }

      final normalizedGrade = s.grade.replaceAll(',', '.');
      return double.tryParse(normalizedGrade) != null;
    }).toList();

    if (gradedSubjects.isEmpty) {
      return "Još nemaš ocijenjenih predmeta.";
    }

    gradedSubjects.sort((a, b) {
      final gradeA = double.tryParse(a.grade.replaceAll(',', '.')) ?? 0;
      final gradeB = double.tryParse(b.grade.replaceAll(',', '.')) ?? 0;
      return gradeB.compareTo(gradeA); // Descending order
    });

    final bestSubject = gradedSubjects.first;
    final bestGrade =
        double.tryParse(bestSubject.grade.replaceAll(',', '.')) ?? 0;

    return "Tvoja najbolja ocjena je ${bestGrade.toStringAsFixed(1)} iz predmeta ${bestSubject.subjectName}.";
  }

  // Get the worst grade info with improved grade format handling
  String _getWorstGradeInfo(Grades grades) {
    final gradedSubjects = grades.subjects.where((s) {
      if (s.grade == 'N/A' || s.grade.isEmpty || s.grade == '-') {
        return false;
      }

      final normalizedGrade = s.grade.replaceAll(',', '.');
      return double.tryParse(normalizedGrade) != null;
    }).toList();

    if (gradedSubjects.isEmpty) {
      return "Još nemaš ocijenjenih predmeta.";
    }

    gradedSubjects.sort((a, b) {
      final gradeA = double.tryParse(a.grade.replaceAll(',', '.')) ?? 0;
      final gradeB = double.tryParse(b.grade.replaceAll(',', '.')) ?? 0;
      return gradeA.compareTo(gradeB); // Ascending order
    });

    final worstSubject = gradedSubjects.first;
    final worstGrade =
        double.tryParse(worstSubject.grade.replaceAll(',', '.')) ?? 0;

    return "Tvoja najniža ocjena je ${worstGrade.toStringAsFixed(1)} iz predmeta ${worstSubject.subjectName}.";
  }

  // Get average grade info with improved grade format handling
  String _getAverageGradeInfo(Grades grades) {
    final gradedSubjects = grades.subjects.where((s) {
      if (s.grade == 'N/A' || s.grade.isEmpty || s.grade == '-') {
        return false;
      }

      final normalizedGrade = s.grade.replaceAll(',', '.');
      return double.tryParse(normalizedGrade) != null;
    }).toList();

    if (gradedSubjects.isEmpty) {
      return "Još nemaš ocijenjenih predmeta.";
    }

    double sum = 0;
    for (final subject in gradedSubjects) {
      final normalizedGrade = subject.grade.replaceAll(',', '.');
      sum += double.tryParse(normalizedGrade) ?? 0;
    }

    final average = sum / gradedSubjects.length;

    // Get the distribution of grades
    Map<int, int> gradeDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final subject in gradedSubjects) {
      final normalizedGrade = subject.grade.replaceAll(',', '.');
      final numericGrade = double.tryParse(normalizedGrade) ?? 0;
      final roundedGrade = numericGrade.round();

      if (roundedGrade >= 1 && roundedGrade <= 5) {
        gradeDistribution[roundedGrade] =
            (gradeDistribution[roundedGrade] ?? 0) + 1;
      }
    }

    String response = "Tvoj prosjek ocjena je ${average.toStringAsFixed(2)}. "
        "Imaš ukupno ${gradedSubjects.length} ocijenjenih predmeta.\n\n";

    // Add distribution info if there are multiple grades
    if (gradedSubjects.length > 1) {
      response += "Distribucija ocjena:\n";

      for (int grade = 5; grade >= 1; grade--) {
        final count = gradeDistribution[grade] ?? 0;
        if (count > 0) {
          response +=
              "Ocjena $grade: $count ${count == 1 ? 'predmet' : 'predmeta'}\n";
        }
      }
    }

    return response;
  }

  // Get all grades info with improved handling of grade formats
  String _getAllGradesInfo(Grades grades) {
    if (grades.subjects.isEmpty) {
      return "Nema dostupnih podataka o ocjenama.";
    }

    // Sort subjects alphabetically
    final sortedSubjects = List<Subject>.from(grades.subjects)
      ..sort((a, b) => a.subjectName.compareTo(b.subjectName));

    String response = "Popis svih ocjena:\n\n";

    for (final subject in sortedSubjects) {
      String grade;
      if (subject.grade == 'N/A' ||
          subject.grade.isEmpty ||
          subject.grade == '-') {
        grade = 'Nije ocijenjeno';
      } else {
        grade = subject.grade;
      }
      response +=
          "${subject.subjectName}: $grade (profesor: ${subject.professor})\n";
    }

    // Add average if possible
    final gradedSubjects = grades.subjects.where((s) {
      if (s.grade == 'N/A' || s.grade.isEmpty || s.grade == '-') {
        return false;
      }

      final normalizedGrade = s.grade.replaceAll(',', '.');
      return double.tryParse(normalizedGrade) != null;
    }).toList();

    if (gradedSubjects.isNotEmpty) {
      double sum = 0;
      for (final subject in gradedSubjects) {
        final normalizedGrade = subject.grade.replaceAll(',', '.');
        sum += double.tryParse(normalizedGrade) ?? 0;
      }

      final average = sum / gradedSubjects.length;
      response += "\nUkupni prosjek: ${average.toStringAsFixed(2)}";
    }

    return response;
  }

  // Get grades summary with improved formatting and better handling of grade formats
  String _getGradesSummary(Grades grades) {
    if (kDebugMode) {
      print('Generating grades summary for ${grades.subjects.length} subjects');
    }

    // Properly handle different grade formats
    final allGradedSubjects = grades.subjects.where((s) {
      // Handle various possible grade formats
      if (s.grade == 'N/A' || s.grade.isEmpty || s.grade == '-') {
        return false;
      }

      // Try to parse as number if possible
      final numericGrade = double.tryParse(s.grade.replaceAll(',', '.'));
      if (numericGrade != null) {
        return true;
      }

      // If it's not a number but still has content, consider it a grade (might be text-based)
      return s.grade.trim().isNotEmpty;
    }).toList();

    // Separate passing and failing subjects
    final passedSubjects = allGradedSubjects.where((s) {
      final normalizedGrade = s.grade.replaceAll(',', '.');
      final numericGrade = double.tryParse(normalizedGrade);
      return numericGrade != null && numericGrade >= 2.0;
    }).toList();

    final failingSubjects = allGradedSubjects.where((s) {
      final normalizedGrade = s.grade.replaceAll(',', '.');
      final numericGrade = double.tryParse(normalizedGrade);
      return numericGrade != null && numericGrade < 2.0;
    }).toList();

    // Get subjects that can't be parsed as numbers but still have values
    final textGradedSubjects = allGradedSubjects.where((s) {
      return double.tryParse(s.grade.replaceAll(',', '.')) == null &&
          s.grade != 'N/A' &&
          s.grade.trim().isNotEmpty;
    }).toList();

    final notGradedSubjects = grades.subjects
        .where((s) => s.grade == 'N/A' || s.grade.isEmpty || s.grade == '-')
        .toList();

    // Calculate average if possible
    double average = 0;
    int count = 0;
    for (final subject in passedSubjects) {
      final normalizedGrade = subject.grade.replaceAll(',', '.');
      final numericGrade = double.tryParse(normalizedGrade);
      if (numericGrade != null) {
        average += numericGrade;
        count++;
      }
    }
    average = count > 0 ? average / count : 0;

    String response = "Evo pregleda tvojih ocjena:\n\n";

    if (count > 0) {
      response += "Tvoj prosjek ocjena je ${average.toStringAsFixed(2)}.\n\n";
    }

    if (allGradedSubjects.isEmpty) {
      response += "Trenutno nemaš ocijenjenih predmeta u sustavu.\n\n";
    }

    // Sort subjects by grade (higher grades first)
    passedSubjects.sort((a, b) {
      final gradeA = double.tryParse(a.grade.replaceAll(',', '.')) ?? 0;
      final gradeB = double.tryParse(b.grade.replaceAll(',', '.')) ?? 0;
      return gradeB.compareTo(gradeA);
    });

    if (passedSubjects.isNotEmpty) {
      response += "Prolazni predmeti (${passedSubjects.length}):\n";
      for (final subject in passedSubjects) {
        response += "- ${subject.subjectName}: ${subject.grade}\n";
      }
      response += "\n";
    }

    if (failingSubjects.isNotEmpty) {
      response +=
          "Predmeti na koje trebaš obratiti pozornost (${failingSubjects.length}):\n";
      for (final subject in failingSubjects) {
        response += "- ${subject.subjectName}: ${subject.grade}\n";
      }
      response += "\n";
    }

    if (textGradedSubjects.isNotEmpty) {
      response +=
          "Predmeti s opisnim ocjenama (${textGradedSubjects.length}):\n";
      for (final subject in textGradedSubjects) {
        response += "- ${subject.subjectName}: ${subject.grade}\n";
      }
      response += "\n";
    }

    if (notGradedSubjects.isNotEmpty) {
      response +=
          "Predmeti koji još nisu ocijenjeni (${notGradedSubjects.length}):\n";
      for (final subject in notGradedSubjects) {
        response += "- ${subject.subjectName}\n";
      }
    }

    return response;
  }

  // Improved schedule information with more context awareness
  Future<String> _getScheduleInfo(String query) async {
    final schedule = await _getSchedule();

    // Check if query is about a specific day
    final days = {
      'ponedjeljak': 'Monday',
      'utorak': 'Tuesday',
      'srijeda': 'Wednesday',
      'četvrtak': 'Thursday',
      'petak': 'Friday',
      'subota': 'Saturday',
      'nedjelja': 'Sunday'
    };

    String? specificDay;
    String? englishDay;

    for (final entry in days.entries) {
      if (query.contains(entry.key)) {
        specificDay = entry.key;
        englishDay = entry.value;
        break;
      }
    }

    // Check if query is about "today" or "tomorrow"
    if (query.contains('danas')) {
      final now = DateTime.now();
      final dayName = _getDayName(now.weekday);
      specificDay = _getCroatianDayName(now.weekday);
      englishDay = dayName;
    } else if (query.contains('sutra')) {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final dayName = _getDayName(tomorrow.weekday);
      specificDay = _getCroatianDayName(tomorrow.weekday);
      englishDay = dayName;
    }

    // If asking about a specific subject in the schedule
    String? specificSubject;
    for (final day in schedule.schedule) {
      for (final subject in day.subjects) {
        if (query.contains(subject.toLowerCase())) {
          specificSubject = subject;
          break;
        }
      }
      if (specificSubject != null) break;
    }

    if (specificSubject != null) {
      return _getSubjectScheduleInfo(schedule, specificSubject);
    }

    if (specificDay != null && englishDay != null) {
      try {
        final daySchedule = schedule.schedule.firstWhere(
            (day) => day.day == englishDay,
            orElse: () => DaySchedule(
                day: englishDay ?? 'Unknown', subjects: [], classrooms: []));

        if (daySchedule.subjects.isEmpty) {
          return "Nemaš nastave zakazane za $specificDay.";
        } else {
          String response = "Tvoj raspored za $specificDay:\n\n";

          // Add classrooms if available
          if (daySchedule.subjects.length == daySchedule.classrooms.length) {
            for (int i = 0; i < daySchedule.subjects.length; i++) {
              final subject = daySchedule.subjects[i];
              final classroom = daySchedule.classrooms[i];
              response += "${i + 1}. $subject (učionica: $classroom)\n";
            }
          } else {
            for (int i = 0; i < daySchedule.subjects.length; i++) {
              response += "${i + 1}. ${daySchedule.subjects[i]}\n";
            }
          }

          return response;
        }
      } catch (e) {
        return "Nisam mogao pronaći informacije o rasporedu za $specificDay.";
      }
    } else {
      // Provide a full week overview with better formatting
      return _getFullWeekSchedule(schedule);
    }
  }

  // Get schedule for a specific subject
  String _getSubjectScheduleInfo(ScheduleSubject schedule, String subjectName) {
    final dayTranslations = {
      'Monday': 'Ponedjeljak',
      'Tuesday': 'Utorak',
      'Wednesday': 'Srijeda',
      'Thursday': 'Četvrtak',
      'Friday': 'Petak',
      'Saturday': 'Subota',
      'Sunday': 'Nedjelja'
    };

    List<String> daysWithSubject = [];

    for (final day in schedule.schedule) {
      if (day.subjects.any(
          (subject) => subject.toLowerCase() == subjectName.toLowerCase())) {
        final croatianDay = dayTranslations[day.day] ?? day.day;
        daysWithSubject.add(croatianDay);
      }
    }

    if (daysWithSubject.isEmpty) {
      return "Predmet '$subjectName' nije pronađen u tvojem rasporedu.";
    } else {
      return "Predmet '$subjectName' imaš u sljedeće dane: ${daysWithSubject.join(', ')}.";
    }
  }

  // Get full week schedule with improved formatting
  String _getFullWeekSchedule(ScheduleSubject schedule) {
    String response = "Evo tvog tjednog rasporeda:\n\n";

    final dayTranslations = {
      'Monday': 'Ponedjeljak',
      'Tuesday': 'Utorak',
      'Wednesday': 'Srijeda',
      'Thursday': 'Četvrtak',
      'Friday': 'Petak',
      'Saturday': 'Subota',
      'Sunday': 'Nedjelja'
    };

    // Ensure days are in correct order (Monday to Sunday)
    final orderedDayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    // Create a map for easy lookup
    final Map<String, DaySchedule> dayMap = {
      for (var day in schedule.schedule) day.day: day
    };

    // Process days in the correct order
    for (final dayName in orderedDayNames) {
      if (dayMap.containsKey(dayName)) {
        final day = dayMap[dayName]!;
        final croatianDay = dayTranslations[day.day] ?? day.day;

        if (day.subjects.isEmpty) {
          response += "$croatianDay: Nema nastave\n";
        } else {
          response += "$croatianDay:\n";

          // Add classrooms if available
          if (day.subjects.length == day.classrooms.length) {
            for (int i = 0; i < day.subjects.length; i++) {
              final subject = day.subjects[i];
              final classroom = day.classrooms[i];
              response += "  ${i + 1}. $subject (učionica: $classroom)\n";
            }
          } else {
            for (int i = 0; i < day.subjects.length; i++) {
              response += "  ${i + 1}. ${day.subjects[i]}\n";
            }
          }
          response += "\n";
        }
      }
    }

    return response;
  }

  // Profile information with improved formatting
  Future<String> _getProfileInfo() async {
    final profile = await _getProfile();

    return "Informacije o učeniku:\n\n"
        "Ime: ${profile.studentName}\n"
        "Škola: ${profile.studentSchool}, ${profile.studentSchoolCity}\n"
        "Razred: ${profile.studentGrade}\n"
        "Školska godina: ${profile.studentSchoolYear}\n"
        "Program: ${profile.studentProgram}\n"
        "Razrednik: ${profile.classMaster}";
  }

  // Improved OpenAI response that provides more context for better answers
  Future<String> _getOpenAIResponse(String query) async {
    // Collect more comprehensive context data for OpenAI
    Map<String, dynamic> contextData = {};

    try {
      // Get all available data for comprehensive context
      final profile = await _getProfile();
      contextData['studentName'] = profile.studentName;
      contextData['studentGrade'] = profile.studentGrade;
      contextData['studentProgram'] = profile.studentProgram;
      contextData['studentSchool'] = profile.studentSchool;

      // Add grades summary
      try {
        final grades = await _getGrades();
        double average = 0;
        int count = 0;

        for (final subject in grades.subjects) {
          if (subject.grade != 'N/A' &&
              double.tryParse(subject.grade) != null) {
            average += double.parse(subject.grade);
            count++;
          }
        }

        if (count > 0) {
          average = average / count;
          contextData['gradesAverage'] = average.toStringAsFixed(2);
          contextData['gradesCount'] = count.toString();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching grades for AI context: $e');
        }
      }

      // Add upcoming test
      try {
        final tests = await _getTests();
        List<TestDetail> allTests = [];

        for (final entry in tests.testsByMonth.entries) {
          allTests.addAll(entry.value);
        }

        final now = DateTime.now();

        final upcomingTests = allTests.where((test) {
          try {
            if (test.testDate.isNotEmpty) {
              final testDate = _parseTestDate(test.testDate);
              return testDate.isAfter(now);
            }
            return false;
          } catch (e) {
            return false;
          }
        }).toList();

        upcomingTests.sort((a, b) {
          final dateA = _parseTestDate(a.testDate);
          final dateB = _parseTestDate(b.testDate);
          return dateA.compareTo(dateB);
        });

        if (upcomingTests.isNotEmpty) {
          contextData['nextTestName'] = upcomingTests.first.testName;
          contextData['nextTestDate'] = upcomingTests.first.testDate;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching tests for AI context: $e');
        }
      }
    } catch (e) {
      // If we can't fetch profile, proceed with minimal context
      if (kDebugMode) {
        print('Error fetching profile for AI context: $e');
      }
    }

    // Build a more comprehensive prompt
    final promptBuilder = StringBuffer();
    promptBuilder.writeln(
        '''"Ti si AI asistent za školsku aplikaciju koji pomaže učeniku s informacijama o školi. "
        "Odgovori prijateljski i korisno na hrvatskom jeziku.VAŽNO: Nemoj koristiti dijakritička slova č, ć, đ, š, ž (niti velika inačica).
Umjesto njih, koristi c, c, d, s, z (ili velika slova C, C, D, S, Z). Evo informacija o učeniku:''');

    contextData.forEach((key, value) {
      promptBuilder.writeln("$key: $value");
    });

    promptBuilder.writeln("\nUčenik je pitao: \"$query\"");
    promptBuilder.writeln(
        "\nAko ne znaš odgovor na temelju konteksta, ljubazno objasni da nemaš te informacije "
        "i predloži što učenik može pitati umjesto toga "
        "(ocjene, raspored, testovi, ili informacije o profilu). "
        "Uvijek odgovori na hrvatskom jeziku. Budi koristan i sažet.");

    // Send to OpenAI with slightly higher temperature for more natural responses
    final response = await _openAIService.generateText(
      prompt: promptBuilder.toString(),
      temperature: 0.8,
      maxTokens: 400,
    );

    return response;
  }

  // UTILITY FUNCTIONS - IMPROVED DATE PARSING AND DAY HANDLING

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "Unknown";
    }
  }

  String _getCroatianDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "ponedjeljak";
      case 2:
        return "utorak";
      case 3:
        return "srijeda";
      case 4:
        return "četvrtak";
      case 5:
        return "petak";
      case 6:
        return "subota";
      case 7:
        return "nedjelja";
      default:
        return "nepoznato";
    }
  }

  // Improved test date parsing with better error handling
  DateTime _parseTestDate(String dateString) {
    try {
      // First, check if the string is empty or null
      if (dateString.isEmpty) {
        throw FormatException('Empty date string');
      }

      // Clean up the date string - remove extra spaces
      final cleaned = dateString.trim();

      // Debug log
      if (kDebugMode) {
        print('Attempting to parse date: "$cleaned"');
      }

      // Special case for partial dates like "26.9." (missing year)
      final partialDatePattern = RegExp(r'(\d{1,2})\.(\d{1,2})\.');
      if (partialDatePattern.hasMatch(cleaned)) {
        final match = partialDatePattern.firstMatch(cleaned);
        if (match != null && match.groupCount >= 2) {
          final day = int.tryParse(match.group(1) ?? '') ?? 1;
          final month = int.tryParse(match.group(2) ?? '') ?? 1;

          // Use current year
          final year = DateTime.now().year;

          // Validate day and month ranges
          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            // Create date with current year
            DateTime result = DateTime(year, month, day);

            // If the date is in the past, assume it's for next year
            if (result.isBefore(DateTime.now())) {
              result = DateTime(year + 1, month, day);
            }

            return result;
          }
        }
      }

      // Format: DD.MM.YYYY
      final dotPattern = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})');
      if (dotPattern.hasMatch(cleaned)) {
        final match = dotPattern.firstMatch(cleaned);
        if (match != null && match.groupCount >= 3) {
          final day = int.tryParse(match.group(1) ?? '') ?? 1;
          final month = int.tryParse(match.group(2) ?? '') ?? 1;
          final year = int.tryParse(match.group(3) ?? '') ?? 2000;

          // Validate day and month ranges
          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            return DateTime(year, month, day);
          }
        }
      }

      // Format: DD-MM-YYYY
      final dashPattern = RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})');
      if (dashPattern.hasMatch(cleaned)) {
        final match = dashPattern.firstMatch(cleaned);
        if (match != null && match.groupCount >= 3) {
          final day = int.tryParse(match.group(1) ?? '') ?? 1;
          final month = int.tryParse(match.group(2) ?? '') ?? 1;
          final year = int.tryParse(match.group(3) ?? '') ?? 2000;

          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            return DateTime(year, month, day);
          }
        }
      }

      // Format: DD/MM/YYYY
      final slashPattern = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
      if (slashPattern.hasMatch(cleaned)) {
        final match = slashPattern.firstMatch(cleaned);
        if (match != null && match.groupCount >= 3) {
          final day = int.tryParse(match.group(1) ?? '') ?? 1;
          final month = int.tryParse(match.group(2) ?? '') ?? 1;
          final year = int.tryParse(match.group(3) ?? '') ?? 2000;

          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            return DateTime(year, month, day);
          }
        }
      }

      // Format: YYYY-MM-DD (ISO format)
      final isoPattern = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
      if (isoPattern.hasMatch(cleaned)) {
        final match = isoPattern.firstMatch(cleaned);
        if (match != null && match.groupCount >= 3) {
          final year = int.tryParse(match.group(1) ?? '') ?? 2000;
          final month = int.tryParse(match.group(2) ?? '') ?? 1;
          final day = int.tryParse(match.group(3) ?? '') ?? 1;

          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            return DateTime(year, month, day);
          }
        }
      }

      // Format for written date like "26. rujan 2023."
      final croatianMonths = {
        'siječanj': 1,
        'veljača': 2,
        'ožujak': 3,
        'travanj': 4,
        'svibanj': 5,
        'lipanj': 6,
        'srpanj': 7,
        'kolovoz': 8,
        'rujan': 9,
        'listopad': 10,
        'studeni': 11,
        'prosinac': 12,
        'siječnja': 1,
        'veljače': 2,
        'ožujka': 3,
        'travnja': 4,
        'svibnja': 5,
        'lipnja': 6,
        'srpnja': 7,
        'kolovoza': 8,
        'rujna': 9,
        'listopada': 10,
        'studenoga': 11,
        'prosinca': 12
      };

      final croatianDatePattern = RegExp(r'(\d{1,2})\.\s+([^\s]+)\s+(\d{4})');
      if (croatianDatePattern.hasMatch(cleaned)) {
        final match = croatianDatePattern.firstMatch(cleaned);
        if (match != null && match.groupCount >= 3) {
          final day = int.tryParse(match.group(1) ?? '') ?? 1;
          final monthName = match.group(2)?.toLowerCase() ?? '';
          final year = int.tryParse(match.group(3) ?? '') ?? 2000;

          final month = croatianMonths[monthName];
          if (month != null && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      }

      // Last resort: try to handle non-standard formats
      // Split by common separators and try to make sense of the parts
      final parts = cleaned.split(RegExp(r'[.\-/ ]'));

      // Filter out empty parts (which can happen with trailing periods)
      final filteredParts = parts.where((part) => part.isNotEmpty).toList();

      if (filteredParts.length >= 2) {
        // Try to extract numbers from the parts
        final numbers = <int>[];
        for (final part in filteredParts) {
          final num = int.tryParse(part.replaceAll(RegExp(r'[^\d]'), ''));
          if (num != null) {
            numbers.add(num);
          }
        }

        // If we got at least 2 numbers, assume they're day, month (use current year)
        if (numbers.length >= 2) {
          int day = numbers[0];
          int month = numbers[1];
          int year = DateTime.now().year;

          // If we have a third number, use it as year
          if (numbers.length >= 3) {
            year = numbers[2];
            // If the year seems too small, it might be a 2-digit year
            if (year < 100) {
              year += 2000;
            }
          }

          // Validate and swap if needed (in case month and day are reversed)
          if (month > 12) {
            final temp = month;
            month = day;
            day = temp;
          }

          // Final validation
          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            DateTime result = DateTime(year, month, day);

            // If using current year made this date in the past, use next year
            if (numbers.length < 3 && result.isBefore(DateTime.now())) {
              result = DateTime(year + 1, month, day);
            }

            return result;
          }
        }
      }

      // If we reach here, try the DateTime.parse as a last resort
      try {
        return DateTime.parse(cleaned);
      } catch (e) {
        if (kDebugMode) {
          print('DateTime.parse failed: $e');
        }
        throw FormatException('Could not parse date: $cleaned');
      }
    } catch (e) {
      // Log the error for debugging
      if (kDebugMode) {
        print('Error parsing date "$dateString": $e');
      }

      // Return a default future date to ensure this test doesn't get selected as the "next test"
      return DateTime.now()
          .add(const Duration(days: 3650)); // 10 years in the future
    }
  }
}
