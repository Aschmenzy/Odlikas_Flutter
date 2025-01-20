import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/specific_subject.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';
import 'package:odlikas_mobilna/database/models/tests.dart';

class ApiService {
  static final String baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://default-url.com';

  Future<StudentProfile> fetchStudentProfile(
      String email, String password) async {
    var url = Uri.parse('$baseUrl/api/Scraper/ScrapeStudentProfile');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return StudentProfile.fromJson(data); //convert to StudentProfile
    } else {
      throw Exception('Failed to fetch student profile');
    }
  }

  Future<Grades> fetchGrades(String email, String password) async {
    var url = Uri.parse('$baseUrl/api/Scraper/ScrapeSubjectsAndProfessors');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Grades.fromJson(data);
    } else {
      throw Exception('Failed to fetch grades');
    }
  }

  Future<List<MonthlyGrades>> fetchSpecificSubjectGrades(
      String email, String password, String subjectId) async {
    var url = Uri.parse(
        '$baseUrl/api/Scraper/ScrapeSpecificSubjectGrades?subjectId=$subjectId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List)
          .map((month) => MonthlyGrades.fromJson(month))
          .toList();
    } else {
      throw Exception('Failed to fetch specific subject grades');
    }
  }

  Future<SubjectDetails> fetchSpecificSubjectDetails(
      String email, String password, String subjectId) async {
    var url = Uri.parse(
        '$baseUrl/api/scraper/ScrapeSpecificSubjectGrades?subjectId=$subjectId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SubjectDetails.fromJson(data);
    } else {
      throw Exception('Failed to fetch specific subject details');
    }
  }

  Future<Tests> fetchTestsDetails(String email, String password) async {
    var url = Uri.parse('$baseUrl/api/scraper/ScrapeTests');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Tests.fromJson(data);
    } else {
      throw Exception('Failed to fetch specific subject details');
    }
  }
}
