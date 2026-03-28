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
    return StudentProfile.fromJson(response.data);
  }

  Future<Grades> fetchGrades() async {
    final response =
        await _dio.get('/api/Scraper/ScrapeSubjectsAndProfessors');
    return Grades.fromJson(response.data);
  }

  Future<List<MonthlyGrades>> fetchSpecificSubjectGrades(
      String subjectId) async {
    final response = await _dio.get(
      '/api/Scraper/ScrapeSpecificSubjectGrades',
      queryParameters: {'subjectId': subjectId},
    );
    return (response.data as List)
        .map((m) => MonthlyGrades.fromJson(m))
        .toList();
  }

  Future<SubjectDetails> fetchSpecificSubjectDetails(String subjectId) async {
    final response = await _dio.get(
      '/api/Scraper/ScrapeSpecificSubjectGrades',
      queryParameters: {'subjectId': subjectId},
    );
    return SubjectDetails.fromJson(response.data);
  }

  Future<Tests> fetchTestsDetails() async {
    final response = await _dio.get('/api/Scraper/ScrapeTests');
    return Tests.fromJson(response.data);
  }

  Future<ScheduleSubject> fetchScheduleSubjects() async {
    final response = await _dio.get('/api/Scraper/ScrapeScheduleTable');
    return ScheduleSubject.fromJson(response.data);
  }
}
