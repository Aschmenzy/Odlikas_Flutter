import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:odlikas_mobilna/database/api/login_service.dart';
import 'package:odlikas_mobilna/exceptions/app_exceptions.dart';

class MockDio extends Mock implements Dio {}

RequestOptions _opts() => RequestOptions(path: '/api/Login');

DioException _dioError(int statusCode) => DioException(
      requestOptions: _opts(),
      response: Response(requestOptions: _opts(), statusCode: statusCode),
      type: DioExceptionType.badResponse,
    );

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    LoginService.overrideDio(mockDio);
  });

  tearDown(() {
    LoginService.resetDio();
  });

  group('LoginService.login()', () {
    test('returns LoginResult on 200 response', () async {
      when(() => mockDio.post(
            '/api/Login',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions: _opts(),
            statusCode: 200,
            data: {
              'token': 'abc123',
              'firebaseToken': 'fb_token',
              'uid': 'user_1',
              'isOdlikasPlus': true,
            },
          ));

      final result = await LoginService.login('test@school.hr', 'pass123');

      expect(result.token, 'abc123');
      expect(result.isOdlikasPlus, isTrue);
      expect(result.uid, 'user_1');
    });

    test('throws AuthException on 401', () {
      when(() => mockDio.post(
            '/api/Login',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(401));

      expect(
        () => LoginService.login('test@school.hr', 'wrong_pass'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws RateLimitException on 429', () {
      when(() => mockDio.post(
            '/api/Login',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(429));

      expect(
        () => LoginService.login('test@school.hr', 'pass'),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('throws ApiException on other error codes', () {
      when(() => mockDio.post(
            '/api/Login',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(503));

      expect(
        () => LoginService.login('test@school.hr', 'pass'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
