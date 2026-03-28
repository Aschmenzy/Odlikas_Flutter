import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'bearer_token';
  static const _keyEmail = 'email';
  static const _keyPassword = 'password';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> readToken() => _storage.read(key: _keyToken);

  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  /// Returns null if either value is missing.
  static Future<({String email, String password})?> readCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  static Future<void> clearAll() => _storage.deleteAll();
}
