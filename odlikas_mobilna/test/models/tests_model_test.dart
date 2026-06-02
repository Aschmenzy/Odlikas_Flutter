import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/database/models/tests.dart';

void main() {
  group('TestDetail.fromJson', () {
    test('parses all fields', () {
      final json = {
        'testName': 'Ispit iz matematike',
        'testDate': '2026-06-10',
        'testDescription': 'Poglavlja 1-5',
      };

      final detail = TestDetail.fromJson(json);

      expect(detail.testName, 'Ispit iz matematike');
      expect(detail.testDate, '2026-06-10');
      expect(detail.testDescription, 'Poglavlja 1-5');
    });
  });

  group('Tests.fromJson', () {
    test('parses tests grouped by month', () {
      final json = {
        'Lipanj': [
          {'testName': 'Mat ispit', 'testDate': '2026-06-10', 'testDescription': ''},
          {'testName': 'Fiz ispit', 'testDate': '2026-06-15', 'testDescription': 'Mehanika'},
        ],
        'Srpanj': [
          {'testName': 'Popravni', 'testDate': '2026-07-01', 'testDescription': ''},
        ],
      };

      final tests = Tests.fromJson(json);

      expect(tests.testsByMonth.keys, containsAll(['Lipanj', 'Srpanj']));
      expect(tests.testsByMonth['Lipanj']!.length, 2);
      expect(tests.testsByMonth['Srpanj']!.length, 1);
      expect(tests.testsByMonth['Lipanj']![0].testName, 'Mat ispit');
    });

    test('returns empty map for empty json', () {
      final tests = Tests.fromJson({});
      expect(tests.testsByMonth, isEmpty);
    });
  });
}
