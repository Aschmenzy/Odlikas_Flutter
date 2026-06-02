import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/exceptions/app_exceptions.dart';

void main() {
  group('RateLimitException', () {
    test('has default Croatian message mentioning 15 minuta', () {
      const e = RateLimitException();
      expect(e.toString(), contains('15 minuta'));
    });

    test('accepts custom message', () {
      const e = RateLimitException('Custom error');
      expect(e.toString(), 'Custom error');
    });

    test('is an Exception', () {
      expect(const RateLimitException(), isA<Exception>());
    });
  });

  group('AuthException', () {
    test('has default Croatian message mentioning lozinku', () {
      const e = AuthException();
      expect(e.toString(), contains('lozinku'));
    });

    test('is an Exception', () {
      expect(const AuthException(), isA<Exception>());
    });
  });

  group('ApiException', () {
    test('includes status code and message in toString', () {
      const e = ApiException(404, 'Not found');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('Not found'));
    });

    test('exposes statusCode and message fields', () {
      const e = ApiException(500, 'Server error');
      expect(e.statusCode, 500);
      expect(e.message, 'Server error');
    });
  });
}
