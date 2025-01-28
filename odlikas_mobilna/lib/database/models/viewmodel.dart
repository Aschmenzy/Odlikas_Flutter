import 'package:flutter/foundation.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
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

  bool get isLoading => _isLoading;
  StudentProfile? get studentProfile => _studentProfile;
  Grades? get grades => _grades;
  List<MonthlyGrades>? get subjectGrades => _subjectGrades;
  List<EvaluationElement>? get evaluationElements => _evaluationElements;
  String? get finalGrade => _finalGrade;
  String? get error => _error;

  Future fetchGrades(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchGrades(email, password);
      _grades = data;
      return _grades;
    } catch (e) {
      print("Error fetching grades: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Your other existing methods remain the same
  Future fetchStudentProfile(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchStudentProfile(email, password);
      _studentProfile = data;
      return _studentProfile;
    } catch (e) {
      print("Error fetching student profile: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSpecificSubjectGrades(
      String email, String password, String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchSpecificSubjectDetails(
          email, password, subjectId);
      _subjectGrades = data.monthlyGrades;
      _evaluationElements = data.evaluationElements;
      _finalGrade = data.finalGrade;
    } catch (e) {
      print("Error fetching specific subject grades: $e");
      _error = e.toString();
      _subjectGrades = null;
      _evaluationElements = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
