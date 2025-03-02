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

      // Extract intent from query using simple keyword matching
      // In a production app, you might want to use more sophisticated NLP here
      if (_isAboutNextTest(normalizedQuery)) {
        return await _getNextTestInfo();
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
      return "Oprostite, dogodila se pogreška prilikom obrade vašeg zahtjeva: ${e.toString()}";
    }
  }

  // INTENT DETECTION HELPERS

  bool _isAboutNextTest(String query) {
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
      'usmeni'
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
      'ocjenjivanje'
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
      'sutra'
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
      'smjer'
    ];
    return profileKeywords.any((keyword) => query.contains(keyword));
  }

  // DATA FETCHING HELPERS

  Future<StudentProfile> _getProfile() async {
    if (_cachedProfile != null) {
      return _cachedProfile!;
    }

    final credentials = _getCredentials();
    _cachedProfile = await _apiService.fetchStudentProfile(
        credentials['email']!, credentials['password']!);
    return _cachedProfile!;
  }

  Future<Grades> _getGrades() async {
    if (_cachedGrades != null) {
      return _cachedGrades!;
    }

    final credentials = _getCredentials();
    _cachedGrades = await _apiService.fetchGrades(
        credentials['email']!, credentials['password']!);
    return _cachedGrades!;
  }

  Future<Tests> _getTests() async {
    if (_cachedTests != null) {
      return _cachedTests!;
    }

    final credentials = _getCredentials();
    _cachedTests = await _apiService.fetchTestsDetails(
        credentials['email']!, credentials['password']!);
    return _cachedTests!;
  }

  Future<ScheduleSubject> _getSchedule() async {
    if (_cachedSchedule != null) {
      return _cachedSchedule!;
    }

    final credentials = _getCredentials();
    _cachedSchedule = await _apiService.fetchScheduleSubjects(
        credentials['email']!, credentials['password']!);
    return _cachedSchedule!;
  }

  // RESPONSE GENERATORS

  Future<String> _getNextTestInfo() async {
    final tests = await _getTests();

    // Get current date for comparison
    final now = DateTime.now();

    // Find the next upcoming test
    TestDetail? nextTest;
    DateTime? nextTestDate;

    for (final entry in tests.testsByMonth.entries) {
      for (final test in entry.value) {
        try {
          // Parse the test date
          final testDate = _parseTestDate(test.testDate);

          // Only consider future tests
          if (testDate.isAfter(now)) {
            // If we haven't found a next test yet, or this test is sooner
            if (nextTest == null || testDate.isBefore(nextTestDate!)) {
              nextTest = test;
              nextTestDate = testDate;
            }
          }
        } catch (e) {
          // Skip tests with invalid dates
          if (kDebugMode) {
            print('Error parsing test date: ${test.testDate}, Error: $e');
          }
        }
      }
    }

    if (nextTest != null) {
      final daysUntil = nextTestDate!.difference(now).inDays;
      String timeDescription;

      if (daysUntil == 0) {
        timeDescription = "danas";
      } else if (daysUntil == 1) {
        timeDescription = "sutra";
      } else {
        timeDescription = "za $daysUntil dana";
      }

      return "Tvoj sljedeći test je \"${nextTest.testName}\" zakazan za ${nextTest.testDate} ($timeDescription). "
          "Detalji: ${nextTest.testDescription}";
    } else {
      return "Dobre vijesti! Nemaš zakazanih nadolazećih testova.";
    }
  }

  Future<String> _getGradesInfo(String query) async {
    final grades = await _getGrades();

    // Check if the query is about a specific subject
    String? specificSubject;
    for (final subject in grades.subjects) {
      if (query.contains(subject.subjectName.toLowerCase())) {
        specificSubject = subject.subjectName;
        break;
      }
    }

    if (specificSubject != null) {
      // Query is about a specific subject
      final subject =
          grades.subjects.firstWhere((s) => s.subjectName == specificSubject);

      return "Tvoja trenutna ocjena iz predmeta $specificSubject je ${subject.grade}. "
          "Ovaj predmet predaje ${subject.professor}.";
    } else {
      // General grade information
      final passedSubjects = grades.subjects
          .where((s) =>
              s.grade != 'N/A' &&
              double.tryParse(s.grade) != null &&
              double.parse(s.grade) >= 2.0)
          .toList();

      final failingSubjects = grades.subjects
          .where((s) =>
              s.grade != 'N/A' &&
              double.tryParse(s.grade) != null &&
              double.parse(s.grade) < 2.0)
          .toList();

      final notGradedSubjects = grades.subjects
          .where((s) => s.grade == 'N/A' || double.tryParse(s.grade) == null)
          .toList();

      // Calculate average if possible
      double average = 0;
      int count = 0;
      for (final subject in passedSubjects) {
        if (double.tryParse(subject.grade) != null) {
          average += double.parse(subject.grade);
          count++;
        }
      }
      average = count > 0 ? average / count : 0;

      String response = "Evo pregleda tvojih ocjena:\n\n";

      if (count > 0) {
        response += "Tvoj prosjek ocjena je ${average.toStringAsFixed(2)}.\n\n";
      }

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

      if (notGradedSubjects.isNotEmpty) {
        response +=
            "Predmeti koji još nisu ocijenjeni (${notGradedSubjects.length}):\n";
        for (final subject in notGradedSubjects) {
          response += "- ${subject.subjectName}\n";
        }
      }

      return response;
    }
  }

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

    if (specificDay != null && englishDay != null) {
      try {
        final daySchedule = schedule.schedule.firstWhere(
            (day) => day.day == englishDay,
            orElse: () =>
                DaySchedule(day: englishDay ?? 'Unknown', subjects: []));

        if (daySchedule.subjects.isEmpty) {
          return "Nemaš nastave zakazane za $specificDay.";
        } else {
          return "Tvoj raspored za $specificDay uključuje: ${daySchedule.subjects.join(', ')}.";
        }
      } catch (e) {
        return "Nisam mogao pronaći informacije o rasporedu za $specificDay.";
      }
    } else {
      // Provide a full week overview
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

      for (final day in schedule.schedule) {
        final croatianDay = dayTranslations[day.day] ?? day.day;
        if (day.subjects.isEmpty) {
          response += "$croatianDay: Nema nastave\n";
        } else {
          response += "$croatianDay: ${day.subjects.join(', ')}\n";
        }
      }

      return response;
    }
  }

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

  Future<String> _getOpenAIResponse(String query) async {
    // First collect context data to provide to OpenAI
    Map<String, dynamic> contextData = {};

    try {
      // Only fetch profile data as basic context
      final profile = await _getProfile();
      contextData['studentName'] = profile.studentName;
      contextData['studentGrade'] = profile.studentGrade;
      contextData['studentProgram'] = profile.studentProgram;
    } catch (e) {
      // If we can't fetch profile, proceed with minimal context
      if (kDebugMode) {
        print('Error fetching profile for AI context: $e');
      }
    }

    // Build a prompt that includes context and the user's query
    final promptBuilder = StringBuffer();
    promptBuilder.writeln(
        "You are an educational assistant helping a student with their school information. "
        "Respond conversationally and helpfully in Croatian language. Here's some context about the student:");

    contextData.forEach((key, value) {
      promptBuilder.writeln("$key: $value");
    });

    promptBuilder.writeln("\nThe student asked: \"$query\"");
    promptBuilder.writeln(
        "\nIf you don't know the answer based on the provided context, "
        "just say you don't have that information yet and suggest what they can ask about instead "
        "(ocjene/grades, raspored/schedule, testovi/tests, or profil/profile information). "
        "Always respond in Croatian language.");

    // Send to OpenAI
    final response = await _openAIService.generateText(
      prompt: promptBuilder.toString(),
      temperature: 0.7,
      maxTokens: 300,
    );

    return response;
  }

  // UTILITY FUNCTIONS

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

  DateTime _parseTestDate(String dateString) {
    final parts = dateString.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid date format: $dateString');
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }
}
