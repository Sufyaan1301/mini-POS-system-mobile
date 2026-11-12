/// Base exception for structured error handling across Data and Presentation layers.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class LocalDatabaseException extends AppException {
  const LocalDatabaseException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class StockException extends AppException {
  const StockException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}
