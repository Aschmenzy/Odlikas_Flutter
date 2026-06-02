import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';

void main() {
  group('StudentProfile.fromJson', () {
    test('parses nested studentProfile object', () {
      final json = {
        'studentProfile': {
          'studentSchool': 'XV. gimnazija',
          'studentSchoolCity': 'Zagreb',
          'studentSchoolYear': '2025./2026.',
          'studentGrade': '4.b',
          'studentName': 'Pero Perić',
          'studentProgram': 'Opća gimnazija',
          'classMaster': 'Ana Anić',
        }
      };

      final profile = StudentProfile.fromJson(json);

      expect(profile.studentName, 'Pero Perić');
      expect(profile.studentSchool, 'XV. gimnazija');
      expect(profile.studentGrade, '4.b');
      expect(profile.classMaster, 'Ana Anić');
    });

    test('falls back to empty strings when studentProfile key is missing', () {
      final profile = StudentProfile.fromJson({});

      expect(profile.studentName, '');
      expect(profile.studentSchool, '');
      expect(profile.studentProgram, '');
    });

    test('falls back to empty strings for individual missing fields', () {
      final json = {
        'studentProfile': {'studentName': 'Test Student'}
      };

      final profile = StudentProfile.fromJson(json);

      expect(profile.studentName, 'Test Student');
      expect(profile.studentSchool, '');
      expect(profile.classMaster, '');
    });
  });
}
