import 'package:odlikas_mobilna/database/api/dio_client.dart';

class MonitoredSubject {
  final String subjectId;
  final String subjectName;

  const MonitoredSubject({required this.subjectId, required this.subjectName});

  factory MonitoredSubject.fromJson(Map<String, dynamic> json) {
    return MonitoredSubject(
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
      };
}

class PendingTaskSet {
  final int id;
  final String subjectName;
  final List<String> tasks;
  final DateTime createdAt;

  const PendingTaskSet({
    required this.id,
    required this.subjectName,
    required this.tasks,
    required this.createdAt,
  });

  factory PendingTaskSet.fromJson(Map<String, dynamic> json) {
    return PendingTaskSet(
      id: json['id'] as int,
      subjectName: json['subjectName'] as String,
      tasks: List<String>.from(json['tasks'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TooManySubjectsException implements Exception {
  final String message;
  const TooManySubjectsException(this.message);
}

class StudyNotificationsService {
  Future<void> setMonitoredSubjects(List<MonitoredSubject> subjects) async {
    try {
      await DioClient.instance.post(
        '/api/StudyNotifications/SetMonitoredSubjects',
        data: subjects.map((s) => s.toJson()).toList(),
      );
    } catch (e) {
      final response = (e as dynamic).response;
      if (response?.statusCode == 403) {
        final message = response?.data?['error'] as String? ??
            'Besplatni plan dozvoljava praćenje 1 predmeta';
        throw TooManySubjectsException(message);
      }
      rethrow;
    }
  }

  Future<List<MonitoredSubject>> getMonitoredSubjects() async {
    final response = await DioClient.instance
        .get('/api/StudyNotifications/GetMonitoredSubjects');
    return (response.data as List)
        .map((e) => MonitoredSubject.fromJson(e))
        .toList();
  }

  Future<List<PendingTaskSet>> getPendingTasks() async {
    final response =
        await DioClient.instance.get('/api/StudyNotifications/GetPendingTasks');
    return (response.data as List)
        .map((e) => PendingTaskSet.fromJson(e))
        .toList();
  }

  Future<void> completeTaskSet(int id) async {
    await DioClient.instance
        .post('/api/StudyNotifications/CompleteTaskSet/$id');
  }
}
