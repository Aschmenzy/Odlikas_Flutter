import 'package:odlikas_mobilna/database/api/dio_client.dart';

class LeaderboardEntry {
  final String nickname;
  final double combinedScore;
  final int currentStreak;
  final double gradeDeltaScore;
  final double streakScore;
  final String? classId;
  final String? city;
  final String? county;

  const LeaderboardEntry({
    required this.nickname,
    required this.combinedScore,
    required this.currentStreak,
    required this.gradeDeltaScore,
    required this.streakScore,
    this.classId,
    this.city,
    this.county,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      nickname: json['nickname'] as String,
      combinedScore: (json['combinedScore'] as num).toDouble(),
      currentStreak: json['currentStreak'] as int,
      gradeDeltaScore: (json['gradeDeltaScore'] as num).toDouble(),
      streakScore: (json['streakScore'] as num).toDouble(),
      classId: json['classId'] as String?,
      city: json['city'] as String?,
      county: json['county'] as String?,
    );
  }
}

class LeaderboardService {
  Future<void> optIn({
    required String nickname,
    required String classId,
    required String schoolId,
    required String city,
    required String county,
  }) async {
    await DioClient.instance.post('/api/Leaderboard/OptIn', data: {
      'nickname': nickname,
      'classId': classId,
      'schoolId': schoolId,
      'city': city,
      'county': county,
    });
  }

  Future<void> optOut() async {
    await DioClient.instance.delete('/api/Leaderboard/OptOut');
  }

  Future<List<LeaderboardEntry>> getClassLeaderboard(
      String schoolId, String classId) async {
    final response = await DioClient.instance
        .get('/api/Leaderboard/School/$schoolId/Class/$classId');
    return (response.data as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }

  Future<List<LeaderboardEntry>> getSchoolLeaderboard(String schoolId) async {
    final response =
        await DioClient.instance.get('/api/Leaderboard/School/$schoolId');
    return (response.data as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }

  Future<List<LeaderboardEntry>> getProgramLeaderboard(String program) async {
    final encoded = Uri.encodeComponent(program);
    final response =
        await DioClient.instance.get('/api/Leaderboard/Program/$encoded');
    return (response.data as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }
}
