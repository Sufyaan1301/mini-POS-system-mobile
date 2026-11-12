import 'dart:convert';
import 'dart:math';

import '../../../../core/error/app_exception.dart';
import '../../../../core/services/secure_session_service.dart';
import '../../../../core/utils/password_hasher.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/cashier_model.dart';

/// Abstracts offline authentication and local session token persistence.
abstract class AuthRepository {
  Future<CashierModel?> checkSession();
  Future<CashierModel> login({
    required String username,
    required String password,
  });
  Future<CashierModel> register({
    required String name,
    required String username,
    required String password,
  });
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required SecureSessionService sessionService,
  })  : _localDataSource = localDataSource,
        _sessionService = sessionService;

  final AuthLocalDataSource _localDataSource;
  final SecureSessionService _sessionService;

  @override
  Future<CashierModel?> checkSession() async {
    final token = await _sessionService.getSessionToken();
    final activeId = await _sessionService.getActiveCashierId();
    if (token == null || token.isEmpty || activeId == null) {
      return null;
    }

    final cashier = await _localDataSource.getCashierById(activeId);
    if (cashier == null) {
      await _sessionService.clearSession();
      return null;
    }
    return cashier;
  }

  @override
  Future<CashierModel> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      throw const ValidationException('Username dan password wajib diisi.');
    }

    final cashier = await _localDataSource.getCashierByUsername(
      normalizedUsername,
    );
    if (cashier == null ||
        !PasswordHasher.verifyPassword(password, cashier.passwordHash)) {
      throw const AuthException('Username atau password salah.');
    }

    await _issueLocalSessionToken(cashier);
    return cashier;
  }

  @override
  Future<CashierModel> register({
    required String name,
    required String username,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedUsername = username.trim();

    if (normalizedName.isEmpty ||
        normalizedUsername.isEmpty ||
        password.isEmpty) {
      throw const ValidationException(
        'Nama, username, dan password wajib diisi.',
      );
    }
    if (normalizedUsername.length < 3) {
      throw const ValidationException('Username minimal 3 karakter.');
    }
    if (password.length < 6) {
      throw const ValidationException('Password minimal 6 karakter.');
    }

    final existing = await _localDataSource.getCashierByUsername(
      normalizedUsername,
    );
    if (existing != null) {
      throw const AuthException('Username sudah terdaftar, gunakan yang lain.');
    }

    final newCashier = CashierModel(
      name: normalizedName,
      username: normalizedUsername,
      passwordHash: PasswordHasher.hashPassword(password),
      createdAt: DateTime.now(),
    );

    // Registration only stores the account; session token is issued on login.
    return _localDataSource.createCashier(newCashier);
  }

  @override
  Future<void> logout() => _sessionService.clearSession();

  Future<void> _issueLocalSessionToken(CashierModel cashier) async {
    final cashierId = cashier.id;
    if (cashierId == null) {
      throw const LocalDatabaseException('ID kasir tidak valid.');
    }
    await _sessionService.saveSession(
      cashierId: cashierId,
      name: cashier.name,
      username: cashier.username,
      token: _generateSessionToken(),
    );
  }

  String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
