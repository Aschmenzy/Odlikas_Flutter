import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odlikas_mobilna/exceptions/app_exceptions.dart';

class LoginResult {
  final String token;
  final String? firebaseToken;
  final String? uid;
  final bool isOdlikasPlus;

  const LoginResult({
    required this.token,
    this.firebaseToken,
    this.uid,
    this.isOdlikasPlus = false,
  });
}

/// Handles only POST /api/Login and DELETE /api/Login.
/// Uses a plain Dio instance — no AuthInterceptor — to avoid circular dependency.
class LoginService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://default-url.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
  ));

  static Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/Login', data: {
        'email': email,
        'password': password,
      });
      return LoginResult(
        token: response.data['token'] as String,
        firebaseToken: response.data['firebaseToken'] as String?,
        uid: response.data['uid'] as String?,
        isOdlikasPlus: response.data['isOdlikasPlus'] as bool? ?? false,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429) throw const RateLimitException();
      if (status == 401) throw const AuthException();
      throw ApiException(status ?? 0, 'Login failed');
    }
  }

  /// Best-effort — failure does not block local logout.
  static Future<void> logout(String token) async {
    try {
      await _dio.delete(
        '/api/Login',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {}
  }
}
