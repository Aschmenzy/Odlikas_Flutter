import 'package:dio/dio.dart';
import 'package:mutex/mutex.dart';
import 'package:odlikas_mobilna/database/api/auth_storage.dart';
import 'package:odlikas_mobilna/database/api/login_service.dart';
import 'package:odlikas_mobilna/exceptions/app_exceptions.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final _mutex = Mutex();

  AuthInterceptor(this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    if (status == 429) {
      handler.reject(err.copyWith(error: const RateLimitException()));
      return;
    }

    // Don't intercept 401 on the login endpoint — that's a credential failure,
    // not an expired session. Intercepting it would cause infinite recursion.
    if (status != 401 || err.requestOptions.path.contains('/api/Login')) {
      handler.next(err);
      return;
    }

    // 401 on a data endpoint — acquire mutex so only one re-login happens
    // even if multiple requests fail simultaneously.
    await _mutex.protect(() async {
      // Another request may have already refreshed the token while we waited.
      final currentToken = await AuthStorage.readToken();
      final sentToken = (err.requestOptions.headers['Authorization'] as String?)
          ?.replaceFirst('Bearer ', '');

      if (currentToken != null && currentToken != sentToken) {
        // Token was already refreshed — retry with the new one.
        try {
          err.requestOptions.headers['Authorization'] = 'Bearer $currentToken';
          final retried = await _dio.fetch(err.requestOptions);
          handler.resolve(retried);
        } catch (e) {
          handler.next(err);
        }
        return;
      }

      final credentials = await AuthStorage.readCredentials();
      if (credentials == null) {
        await AuthStorage.clearAll();
        handler.next(err);
        return;
      }

      try {
        final loginResult =
            await LoginService.login(credentials.email, credentials.password);
        await AuthStorage.saveToken(loginResult.token);
        err.requestOptions.headers['Authorization'] = 'Bearer ${loginResult.token}';
        final retried = await _dio.fetch(err.requestOptions);
        handler.resolve(retried);
      } catch (_) {
        // Re-login failed — wipe storage so StartupRouter forces manual login.
        await AuthStorage.clearAll();
        handler.next(err);
      }
    });
  }
}
