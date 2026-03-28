import 'package:flutter/foundation.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';
import 'package:odlikas_mobilna/database/models/specific_subject.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';

class HomePageViewModel extends ChangeNotifier {
  final ApiService _apiService;

  HomePageViewModel(this._apiService);

  bool _isLoading = false;
  StudentProfile? _studentProfile;
  Grades? _grades;
  List<MonthlyGrades>? _subjectGrades;
  List<EvaluationElement>? _evaluationElements;
  String? _finalGrade;
  String? _error;
  ScheduleSubject? _scheduleSubject;

  bool get isLoading => _isLoading;
  StudentProfile? get studentProfile => _studentProfile;
  Grades? get grades => _grades;
  List<MonthlyGrades>? get subjectGrades => _subjectGrades;
  List<EvaluationElement>? get evaluationElements => _evaluationElements;
  String? get finalGrade => _finalGrade;
  String? get error => _error;
  ScheduleSubject? get scheduleSubject => _scheduleSubject;

  Future fetchGrades() async {
    _isLoading = true;
    notifyListeners();

    try {
      _grades = await _apiService.fetchGrades();
      return _grades;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future fetchStudentProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _studentProfile = await _apiService.fetchStudentProfile();
      return _studentProfile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSpecificSubjectGrades(String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchSpecificSubjectDetails(subjectId);
      _subjectGrades = data.monthlyGrades;
      _evaluationElements = data.evaluationElements;
      _finalGrade = data.finalGrade;
    } catch (e) {
      _error = e.toString();
      _subjectGrades = null;
      _evaluationElements = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSchedule(ScheduleSubject schedule) {
    _scheduleSubject = schedule;
    notifyListeners();
  }

  Future<void> fetchScheduleSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _scheduleSubject = await _apiService.fetchScheduleSubjects();
    } catch (e) {
      _error = e.toString();
      _scheduleSubject = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> getSubjectsForDay(String day) {
    return _scheduleSubject?.schedule
            .firstWhere((schedule) => schedule.day == day,
                orElse: () =>
                    DaySchedule(day: day, subjects: [], classrooms: []))
            .subjects ??
        [];
  }

  List<String> get allDays {
    return _scheduleSubject?.schedule.map((s) => s.day).toList() ?? [];
  }

  bool isDayEmpty(String day) {
    return getSubjectsForDay(day).isEmpty;
  }
}
