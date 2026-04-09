import 'package:odlikas_mobilna/database/api/dio_client.dart';

class PomodoroSessionResult {
  final int currentStreak;
  final int longestStreak;
  final int todaySessions;
  final int todayMinutes;
  final bool? capped;

  const PomodoroSessionResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.todaySessions,
    required this.todayMinutes,
    this.capped,
  });

  factory PomodoroSessionResult.fromJson(Map<String, dynamic> json) {
    return PomodoroSessionResult(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      todaySessions: json['todaySessions'] as int,
      todayMinutes: json['todayMinutes'] as int,
      capped: json['capped'] as bool?,
    );
  }
}

class PomodoroApiService {
  Future<PomodoroSessionResult> completeSession() async {
    final response =
        await DioClient.instance.post('/api/Pomodoro/CompleteSession');
    return PomodoroSessionResult.fromJson(response.data);
  }

  Future<PomodoroSessionResult> getStreak() async {
    final response = await DioClient.instance.get('/api/Pomodoro/GetStreak');
    return PomodoroSessionResult.fromJson(response.data);
  }
}
