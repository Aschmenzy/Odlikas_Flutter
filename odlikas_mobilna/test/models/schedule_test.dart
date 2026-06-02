import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';

void main() {
  group('DaySchedule.fromJson', () {
    test('parses day, subjects, and classrooms', () {
      final json = {
        'day': 'Ponedjeljak',
        'subjects': ['Matematika', 'Fizika'],
        'classrooms': ['A101', 'B203'],
      };

      final day = DaySchedule.fromJson(json);

      expect(day.day, 'Ponedjeljak');
      expect(day.subjects, ['Matematika', 'Fizika']);
      expect(day.classrooms, ['A101', 'B203']);
    });

    test('defaults classrooms to 8 empty strings when absent from JSON', () {
      final json = {
        'day': 'Utorak',
        'subjects': ['Kemija'],
      };

      final day = DaySchedule.fromJson(json);

      expect(day.classrooms, List.filled(8, ''));
      expect(day.classrooms.length, 8);
    });

    test('toJson round-trips correctly', () {
      final original = DaySchedule(
        day: 'Srijeda',
        subjects: ['Engleski'],
        classrooms: ['C301'],
      );

      final decoded = DaySchedule.fromJson(original.toJson());

      expect(decoded.day, original.day);
      expect(decoded.subjects, original.subjects);
      expect(decoded.classrooms, original.classrooms);
    });
  });

  group('ScheduleSubject.fromJson', () {
    test('parses multiple days', () {
      final json = {
        'schedule': [
          {'day': 'Ponedjeljak', 'subjects': ['Matematika']},
          {'day': 'Utorak', 'subjects': ['Fizika']},
        ]
      };

      final schedule = ScheduleSubject.fromJson(json);

      expect(schedule.schedule.length, 2);
      expect(schedule.schedule[0].day, 'Ponedjeljak');
      expect(schedule.schedule[1].day, 'Utorak');
    });
  });
}
