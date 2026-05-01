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

  // GET /GetStreak returns the streak object flat, no capped field
  factory PomodoroSessionResult.fromStreakJson(Map<String, dynamic> json) {
    return PomodoroSessionResult(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      todaySessions: (json['todaySessions'] as num?)?.toInt() ?? 0,
      todayMinutes: (json['todayMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  // POST /CompleteSession returns { streak: {...}, capped: bool }
  factory PomodoroSessionResult.fromCompleteJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>;
    return PomodoroSessionResult(
      currentStreak: (streak['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (streak['longestStreak'] as num?)?.toInt() ?? 0,
      todaySessions: (streak['todaySessions'] as num?)?.toInt() ?? 0,
      todayMinutes: (streak['todayMinutes'] as num?)?.toInt() ?? 0,
      capped: json['capped'] as bool?,
    );
  }
}

class PomodoroApiService {
  Future<PomodoroSessionResult> completeSession() async {
    final response =
        await DioClient.instance.post('/api/Pomodoro/CompleteSession');
    return PomodoroSessionResult.fromCompleteJson(
        response.data as Map<String, dynamic>);
  }

  Future<PomodoroSessionResult> getStreak() async {
    final response = await DioClient.instance.get('/api/Pomodoro/GetStreak');
    return PomodoroSessionResult.fromStreakJson(
        response.data as Map<String, dynamic>);
  }
}
