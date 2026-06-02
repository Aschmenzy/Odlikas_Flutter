import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';

void main() {
  group('Subject.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'subjectName': 'Matematika',
        'grade': '5',
        'professor': 'Horvat',
        'subjectId': 'mat-101',
      };

      final subject = Subject.fromJson(json);

      expect(subject.subjectName, 'Matematika');
      expect(subject.grade, '5');
      expect(subject.professor, 'Horvat');
      expect(subject.subjectId, 'mat-101');
    });

    test('falls back to empty strings and N/A for missing fields', () {
      final subject = Subject.fromJson({});

      expect(subject.subjectName, '');
      expect(subject.grade, 'N/A');
      expect(subject.professor, '');
      expect(subject.subjectId, '');
    });
  });

  group('Grades.fromJson', () {
    test('parses list of subjects', () {
      final json = {
        'subjects': [
          {'subjectName': 'Fizika', 'grade': '4', 'professor': 'Novak', 'subjectId': 'fiz-1'},
          {'subjectName': 'Kemija', 'grade': '3', 'professor': 'Babić', 'subjectId': 'kem-1'},
        ]
      };

      final grades = Grades.fromJson(json);

      expect(grades.subjects.length, 2);
      expect(grades.subjects[0].subjectName, 'Fizika');
      expect(grades.subjects[1].grade, '3');
    });

    test('returns empty subjects list for empty array', () {
      final grades = Grades.fromJson({'subjects': []});

      expect(grades.subjects, isEmpty);
    });
  });
}
