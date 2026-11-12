import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the active cashier login token & session securely via `flutter_secure_storage`.
class SecureSessionService {
  SecureSessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _keyCashierId = 'session_cashier_id';
  static const String _keyCashierName = 'session_cashier_name';
  static const String _keyCashierUsername = 'session_cashier_username';
  static const String _keySessionToken = 'session_token';

  Future<void> saveSession({
    required int cashierId,
    required String name,
    required String username,
    required String token,
  }) async {
    await Future.wait([
      _storage.write(key: _keyCashierId, value: cashierId.toString()),
      _storage.write(key: _keyCashierName, value: name),
      _storage.write(key: _keyCashierUsername, value: username),
      _storage.write(key: _keySessionToken, value: token),
    ]);
  }

  Future<int?> getActiveCashierId() async {
    final raw = await _storage.read(key: _keyCashierId);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<String?> getSessionToken() => _storage.read(key: _keySessionToken);

  Future<String?> getActiveCashierName() => _storage.read(key: _keyCashierName);

  Future<String?> getActiveCashierUsername() =>
      _storage.read(key: _keyCashierUsername);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _keyCashierId),
      _storage.delete(key: _keyCashierName),
      _storage.delete(key: _keyCashierUsername),
      _storage.delete(key: _keySessionToken),
    ]);
  }
}
