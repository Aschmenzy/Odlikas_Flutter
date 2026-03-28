class RateLimitException implements Exception {
  final String message;
  const RateLimitException(
      [this.message =
          'Previše neuspjelih pokušaja. Pokušaj ponovo za 15 minuta.']);
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  const AuthException(
      [this.message = 'Prijava nije uspjela. Provjeri email i lozinku.']);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
