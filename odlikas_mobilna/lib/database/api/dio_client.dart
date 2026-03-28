import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:odlikas_mobilna/database/api/auth_interceptor.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance => _instance ??= _build();

  /// Call after logout to force re-initialisation with a clean token state.
  static void reset() => _instance = null;

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://default-url.com',
      connectTimeout: const Duration(seconds: 15),
      // Some scraper endpoints are slow — keep receive timeout generous.
      receiveTimeout: const Duration(seconds: 120),
      contentType: 'application/json',
    ));
    dio.interceptors.add(AuthInterceptor(dio));
    return dio;
  }
}
