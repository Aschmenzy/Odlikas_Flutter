import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';
import 'package:odlikas_mobilna/database/models/tests.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';
import 'package:odlikas_mobilna/services/openAiService.dart';

class AIAssistantService {
  final ApiService _apiService;
  final OpenAIService _openAIService;

  // Cached API data to avoid redundant E-Dnevnik calls within a session
  StudentProfile? _cachedProfile;
  Grades? _cachedGrades;
  Tests? _cachedTests;
  ScheduleSubject? _cachedSchedule;

  static final AIAssistantService _instance = AIAssistantService._internal();
  factory AIAssistantService() => _instance;

  AIAssistantService._internal()
      : _apiService = ApiService(),
        _openAIService = OpenAIService();

  String _getEmail() => (Hive.box('User').get('email') as String?) ?? '';
  bool get hasCredentials => _getEmail().isNotEmpty;

  void clearCache() {
    _cachedProfile = null;
    _cachedGrades = null;
    _cachedTests = null;
    _cachedSchedule = null;
  }

  // ──────────────────────────────────────────────
  // Main entry point — two-model pipeline
  // ──────────────────────────────────────────────

  Future<String> processQuery(String query) async {
    if (!hasCredentials) {
      return 'Molimo prvo se prijavite kako biste koristili AI asistenta.';
    }

    try {
      // MODEL 1: gpt-4o-mini classifies intent and extracts entities (~120 tokens)
      final intent = await _openAIService.classifyIntent(query);

      if (kDebugMode) {
        debugPrint('Intent: ${intent.intent}, needsApi: ${intent.needsApi}, '
            'subject: ${intent.subject}, day: ${intent.dayOfWeek}, '
            'summary: ${intent.summary}');
      }

      // Fetch only the data the intent actually needs — no redundant API calls
      String contextData = '';

      switch (intent.intent) {
        case 'grades':
          try {
            contextData =
                _buildGradesContext(await _getGrades(), intent.subject);
          } catch (e) {
            contextData = 'Podaci o ocjenama trenutno nisu dostupni.';
          }
          break;

        case 'tests':
          try {
            contextData = _buildTestsContext(await _getTests());
          } catch (e) {
            contextData = 'Podaci o testovima trenutno nisu dostupni.';
          }
          break;

        case 'schedule':
          try {
            contextData =
                _buildScheduleContext(await _getSchedule(), intent.dayOfWeek);
          } catch (e) {
            contextData = 'Podaci o rasporedu trenutno nisu dostupni.';
          }
          break;

        case 'profile':
          try {
            contextData = _buildProfileContext(await _getProfile());
          } catch (e) {
            contextData = 'Podaci o profilu trenutno nisu dostupni.';
          }
          break;

        default:
          // general — no API call needed, Model 2 answers from its own knowledge
          break;
      }

      // MODEL 2: gpt-3.5-turbo generates the final answer with injected context
      return await _openAIService.generateResponse(
        userQuery: query,
        intentSummary: intent.summary,
        contextData: contextData,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in processQuery: $e');
        if (e is Error) debugPrint(e.stackTrace.toString());
      }
      return 'Oprostite, doslo je do pogreske: ${e.toString()}';
    }
  }

  // ──────────────────────────────────────────────
  // Data fetchers (with session-level caching)
  // ──────────────────────────────────────────────

  Future<StudentProfile> _getProfile() async {
    _cachedProfile ??= await _apiService.fetchStudentProfile();
    return _cachedProfile!;
  }

  Future<Grades> _getGrades() async {
    _cachedGrades ??= await _apiService.fetchGrades();
    return _cachedGrades!;
  }

  Future<Tests> _getTests() async {
    _cachedTests ??= await _apiService.fetchTestsDetails();
    return _cachedTests!;
  }

  Future<ScheduleSubject> _getSchedule() async {
    _cachedSchedule ??= await _apiService.fetchScheduleSubjects();
    return _cachedSchedule!;
  }

  // ──────────────────────────────────────────────
  // Context builders — produce compact text for Model 2
  // ──────────────────────────────────────────────

  String _buildGradesContext(Grades grades, String? specificSubject) {
    if (grades.subjects.isEmpty) return 'Nema podataka o ocjenama.';

    final buffer = StringBuffer();

    // Highlight the specific subject if Model 1 identified one
    if (specificSubject != null) {
      final matches = grades.subjects.where((s) =>
          s.subjectName.toLowerCase().contains(specificSubject.toLowerCase()));
      if (matches.isNotEmpty) {
        final s = matches.first;
        buffer.writeln('Trazeni predmet: ${s.subjectName}');
        buffer.writeln('Ocjena: ${s.grade}');
        buffer.writeln('Profesor: ${s.professor}');
        buffer.writeln();
      }
    }

    // Calculate and show average
    final graded = grades.subjects.where((s) {
      final n = s.grade.replaceAll(',', '.');
      return double.tryParse(n) != null;
    }).toList();

    if (graded.isNotEmpty) {
      final avg = graded.fold(
              0.0,
              (sum, s) =>
                  sum + (double.tryParse(s.grade.replaceAll(',', '.')) ?? 0)) /
          graded.length;
      buffer.writeln(
          'Prosjek: ${avg.toStringAsFixed(2)} (${graded.length} predmeta ocijenjeno)');
      buffer.writeln();
    }

    // Compact list of all grades
    buffer.writeln('Sve ocjene:');
    for (final s in grades.subjects) {
      final grade = (s.grade.isEmpty || s.grade == 'N/A' || s.grade == '-')
          ? 'nije ocijenjeno'
          : s.grade;
      buffer.writeln('- ${s.subjectName}: $grade (${s.professor})');
    }

    return buffer.toString();
  }

  String _buildTestsContext(Tests tests) {
    final now = DateTime.now();

    final allTests = <TestDetail>[];
    for (final entry in tests.testsByMonth.entries) {
      allTests.addAll(entry.value);
    }

    if (allTests.isEmpty) return 'Nema podataka o testovima.';

    final sorted = _getSortedTests(allTests);
    final upcoming = sorted.where((t) {
      try {
        return _parseTestDate(t.testDate).isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
    final past = sorted.where((t) {
      try {
        return _parseTestDate(t.testDate).isBefore(now);
      } catch (_) {
        return false;
      }
    }).toList();

    final buffer = StringBuffer();

    if (upcoming.isNotEmpty) {
      buffer.writeln('Nadolazeci testovi (${upcoming.length}):');
      for (final t in upcoming.take(8)) {
        final days = _getDaysUntilTest(t.testDate, now);
        final daysStr = days != null
            ? days == 0
                ? ' (danas)'
                : days == 1
                    ? ' (sutra)'
                    : ' (za $days dana)'
            : '';
        buffer.writeln('- ${t.testName}: ${t.testDate}$daysStr');
        if (t.testDescription.isNotEmpty) {
          buffer.writeln('  Opis: ${t.testDescription}');
        }
      }
    } else {
      buffer.writeln('Nema nadolazecih testova.');
    }

    if (past.isNotEmpty) {
      buffer.writeln('Broj proslog testova: ${past.length}');
    }

    return buffer.toString();
  }

  String _buildScheduleContext(ScheduleSubject schedule, String? dayOfWeek) {
    const dayTranslations = {
      'Monday': 'Ponedjeljak',
      'Tuesday': 'Utorak',
      'Wednesday': 'Srijeda',
      'Thursday': 'Cetvrtak',
      'Friday': 'Petak',
      'Saturday': 'Subota',
      'Sunday': 'Nedjelja',
    };

    final buffer = StringBuffer();

    if (dayOfWeek != null) {
      final daySchedule = schedule.schedule
          .where((d) => d.day.toLowerCase() == dayOfWeek.toLowerCase())
          .toList();

      if (daySchedule.isNotEmpty && daySchedule.first.subjects.isNotEmpty) {
        final day = daySchedule.first;
        buffer.writeln('Raspored za ${dayTranslations[day.day] ?? day.day}:');
        for (int i = 0; i < day.subjects.length; i++) {
          final classroom =
              i < day.classrooms.length ? ' (${day.classrooms[i]})' : '';
          buffer.writeln('${i + 1}. ${day.subjects[i]}$classroom');
        }
      } else {
        buffer.writeln('Nema nastave za trazeni dan.');
      }
    } else {
      // Full week — compact one-liner per day
      buffer.writeln('Tjedni raspored:');
      const order = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final dayMap = {for (final d in schedule.schedule) d.day: d};
      for (final name in order) {
        final day = dayMap[name];
        if (day == null || day.subjects.isEmpty) continue;
        buffer.writeln(
            '${dayTranslations[name] ?? name}: ${day.subjects.join(', ')}');
      }
    }

    return buffer.toString();
  }

  String _buildProfileContext(StudentProfile profile) =>
      'Ucenik: ${profile.studentName}\n'
      'Skola: ${profile.studentSchool}, ${profile.studentSchoolCity}\n'
      'Razred: ${profile.studentGrade}\n'
      'Skolska godina: ${profile.studentSchoolYear}\n'
      'Program: ${profile.studentProgram}\n'
      'Razrednik: ${profile.classMaster}';

  // ──────────────────────────────────────────────
  // Utilities
  // ──────────────────────────────────────────────

  List<TestDetail> _getSortedTests(List<TestDetail> tests) {
    final withDates = <MapEntry<TestDetail, DateTime>>[];
    for (final t in tests) {
      try {
        if (t.testDate.isNotEmpty) {
          withDates.add(MapEntry(t, _parseTestDate(t.testDate)));
        }
      } catch (_) {}
    }
    withDates.sort((a, b) => a.value.compareTo(b.value));
    return withDates.map((e) => e.key).toList();
  }

  int? _getDaysUntilTest(String dateStr, DateTime now) {
    try {
      final testDate = _parseTestDate(dateStr);
      final today = DateTime(now.year, now.month, now.day);
      final testDay = DateTime(testDate.year, testDate.month, testDate.day);
      return testDay.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  DateTime _parseTestDate(String dateString) {
    try {
      if (dateString.isEmpty) throw FormatException('Empty date');
      final s = dateString.trim();

      // DD.MM.YYYY
      final full = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})');
      if (full.hasMatch(s)) {
        final m = full.firstMatch(s)!;
        final d = int.parse(m.group(1)!),
            mo = int.parse(m.group(2)!),
            y = int.parse(m.group(3)!);
        if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12) return DateTime(y, mo, d);
      }

      // DD.MM. (partial — current year)
      final partial = RegExp(r'(\d{1,2})\.(\d{1,2})\.');
      if (partial.hasMatch(s)) {
        final m = partial.firstMatch(s)!;
        final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
        final y = DateTime.now().year;
        if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12) {
          var result = DateTime(y, mo, d);
          if (result.isBefore(DateTime.now())) result = DateTime(y + 1, mo, d);
          return result;
        }
      }

      // DD-MM-YYYY
      final dash = RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})');
      if (dash.hasMatch(s)) {
        final m = dash.firstMatch(s)!;
        final d = int.parse(m.group(1)!),
            mo = int.parse(m.group(2)!),
            y = int.parse(m.group(3)!);
        if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12) return DateTime(y, mo, d);
      }

      // YYYY-MM-DD (ISO)
      final iso = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
      if (iso.hasMatch(s)) {
        final m = iso.firstMatch(s)!;
        final y = int.parse(m.group(1)!),
            mo = int.parse(m.group(2)!),
            d = int.parse(m.group(3)!);
        if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12) return DateTime(y, mo, d);
      }

      // Croatian written date: "26. rujan 2023."
      final months = {
        'sijecanj': 1,
        'veljaca': 2,
        'ozujak': 3,
        'travanj': 4,
        'svibanj': 5,
        'lipanj': 6,
        'srpanj': 7,
        'kolovoz': 8,
        'rujan': 9,
        'listopad': 10,
        'studeni': 11,
        'prosinac': 12,
        'sijecnja': 1,
        'veljace': 2,
        'ozujka': 3,
        'travnja': 4,
        'svibnja': 5,
        'lipnja': 6,
        'srpnja': 7,
        'kolovoza': 8,
        'rujna': 9,
        'listopada': 10,
        'studenoga': 11,
        'prosinca': 12,
      };
      final written = RegExp(r'(\d{1,2})\.\s+([^\s]+)\s+(\d{4})');
      if (written.hasMatch(s)) {
        final m = written.firstMatch(s)!;
        final d = int.parse(m.group(1)!);
        final mo = months[m.group(2)!.toLowerCase()];
        final y = int.parse(m.group(3)!);
        if (mo != null && d >= 1 && d <= 31) return DateTime(y, mo, d);
      }

      return DateTime.parse(s);
    } catch (e) {
      if (kDebugMode) debugPrint('_parseTestDate failed for "$dateString": $e');
      return DateTime.now().add(const Duration(days: 3650));
    }
  }
}
