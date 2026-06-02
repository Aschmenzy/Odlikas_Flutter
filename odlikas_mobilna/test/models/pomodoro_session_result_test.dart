import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/services/pomodoro_api_service.dart';

void main() {
  group('PomodoroSessionResult.fromStreakJson', () {
    test('parses flat streak response', () {
      final json = {
        'currentStreak': 5,
        'longestStreak': 12,
        'todaySessions': 3,
        'todayMinutes': 75,
      };

      final result = PomodoroSessionResult.fromStreakJson(json);

      expect(result.currentStreak, 5);
      expect(result.longestStreak, 12);
      expect(result.todaySessions, 3);
      expect(result.todayMinutes, 75);
      expect(result.capped, isNull);
    });

    test('defaults all numeric fields to 0 when keys are missing', () {
      final result = PomodoroSessionResult.fromStreakJson({});

      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.todaySessions, 0);
      expect(result.todayMinutes, 0);
    });
  });

  group('PomodoroSessionResult.fromCompleteJson', () {
    test('parses nested streak with capped flag true', () {
      final json = {
        'streak': {
          'currentStreak': 7,
          'longestStreak': 10,
          'todaySessions': 8,
          'todayMinutes': 200,
        },
        'capped': true,
      };

      final result = PomodoroSessionResult.fromCompleteJson(json);

      expect(result.currentStreak, 7);
      expect(result.todaySessions, 8);
      expect(result.capped, isTrue);
    });

    test('capped is null when key is absent', () {
      final json = {
        'streak': {
          'currentStreak': 1,
          'longestStreak': 1,
          'todaySessions': 1,
          'todayMinutes': 25,
        },
      };

      final result = PomodoroSessionResult.fromCompleteJson(json);

      expect(result.capped, isNull);
    });
  });
}
