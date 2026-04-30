import 'package:dio/dio.dart';
import 'package:odlikas_mobilna/database/api/dio_client.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';
import 'package:odlikas_mobilna/database/models/specific_subject.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';
import 'package:odlikas_mobilna/database/models/tests.dart';

class ApiService {
  Dio get _dio => DioClient.instance;

  Future<StudentProfile> fetchStudentProfile() async {
    final response = await _dio.get('/api/Scraper/ScrapeStudentProfile');
    return StudentProfile.fromJson(response.data['data']);
  }

  Future<Grades> fetchGrades() async {
    final response =
        await _dio.get('/api/Scraper/ScrapeSubjectsAndProfessors');
    return Grades.fromJson(response.data['data']);
  }

  Future<List<MonthlyGrades>> fetchSpecificSubjectGrades(
      String subjectId) async {
    final response = await _dio.get(
      '/api/Scraper/ScrapeSpecificSubjectGrades',
      queryParameters: {'subjectId': subjectId},
    );
    return (response.data['data'] as List)
        .map((m) => MonthlyGrades.fromJson(m))
        .toList();
  }

  Future<SubjectDetails> fetchSpecificSubjectDetails(String subjectId) async {
    final response = await _dio.get(
      '/api/Scraper/ScrapeSpecificSubjectGrades',
      queryParameters: {'subjectId': subjectId},
    );
    return SubjectDetails.fromJson(response.data['data']);
  }

  Future<Tests> fetchTestsDetails() async {
    final response = await _dio.get('/api/Scraper/ScrapeTests');
    return Tests.fromJson(response.data['data']);
  }

  Future<ScheduleSubject> fetchScheduleSubjects() async {
    final response = await _dio.get('/api/Scraper/ScrapeScheduleTable');
    return ScheduleSubject.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> getPomodoroStreak() async {
    final response = await _dio.get('/api/Pomodoro/GetStreak');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completePomodoroSession() async {
    final response = await _dio.post('/api/Pomodoro/CompleteSession');
    return response.data['data'] as Map<String, dynamic>;
  }
}
