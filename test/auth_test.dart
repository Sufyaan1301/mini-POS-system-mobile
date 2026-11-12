import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos_system/core/error/app_exception.dart';
import 'package:mini_pos_system/core/services/secure_session_service.dart';
import 'package:mini_pos_system/core/utils/password_hasher.dart';
import 'package:mini_pos_system/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mini_pos_system/features/auth/data/models/cashier_model.dart';
import 'package:mini_pos_system/features/auth/data/repositories/auth_repository.dart';
import 'package:mini_pos_system/features/auth/presentation/bloc/auth_bloc.dart';

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  final Map<int, CashierModel> _byId = {};
  int _nextId = 1;

  @override
  Future<CashierModel> createCashier(CashierModel cashier) async {
    final created = CashierModel(
      id: _nextId++,
      name: cashier.name,
      username: cashier.username,
      passwordHash: cashier.passwordHash,
      createdAt: cashier.createdAt,
    );
    _byId[created.id!] = created;
    return created;
  }

  @override
  Future<CashierModel?> getCashierById(int id) async => _byId[id];

  @override
  Future<CashierModel?> getCashierByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    for (final cashier in _byId.values) {
      if (cashier.username.toLowerCase() == normalized) {
        return cashier;
      }
    }
    return null;
  }
}

class _FakeSecureSessionService extends SecureSessionService {
  int? _cashierId;
  String? _name;
  String? _username;
  String? _token;

  @override
  Future<void> saveSession({
    required int cashierId,
    required String name,
    required String username,
    required String token,
  }) async {
    _cashierId = cashierId;
    _name = name;
    _username = username;
    _token = token;
  }

  @override
  Future<int?> getActiveCashierId() async => _cashierId;

  @override
  Future<String?> getSessionToken() async => _token;

  @override
  Future<String?> getActiveCashierName() async => _name;

  @override
  Future<String?> getActiveCashierUsername() async => _username;

  @override
  Future<void> clearSession() async {
    _cashierId = null;
    _name = null;
    _username = null;
    _token = null;
  }
}

void main() {
  group('PasswordHasher', () {
    test('hashes and verifies password with unique per-call salt', () {
      final hash1 = PasswordHasher.hashPassword('secret123');
      final hash2 = PasswordHasher.hashPassword('secret123');

      expect(hash1, isNot(equals(hash2)));
      expect(PasswordHasher.verifyPassword('secret123', hash1), isTrue);
      expect(PasswordHasher.verifyPassword('wrongpass', hash1), isFalse);
    });
  });

  group('AuthRepositoryImpl', () {
    late _FakeAuthLocalDataSource dataSource;
    late _FakeSecureSessionService sessionService;
    late AuthRepositoryImpl repository;

    setUp(() {
      dataSource = _FakeAuthLocalDataSource();
      sessionService = _FakeSecureSessionService();
      repository = AuthRepositoryImpl(
        localDataSource: dataSource,
        sessionService: sessionService,
      );
    });

    test('register creates cashier without issuing session token', () async {
      final cashier = await repository.register(
        name: 'Dils',
        username: 'dils_kasir',
        password: 'password123',
      );

      expect(cashier.id, 1);
      expect(await sessionService.getSessionToken(), isNull);
      expect(await sessionService.getActiveCashierId(), isNull);
      expect(await repository.checkSession(), isNull);
    });

    test('register rejects duplicate username (case-insensitive)', () async {
      await repository.register(
        name: 'Dils',
        username: 'KasirSatu',
        password: 'password123',
      );

      expect(
        () => repository.register(
          name: 'Dils 2',
          username: 'kasirsatu',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('login fails with wrong password and issues token on success',
        () async {
      await repository.register(
        name: 'Dils',
        username: 'kasir1',
        password: 'password123',
      );

      expect(
        () => repository.login(username: 'kasir1', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );

      final loggedIn = await repository.login(
        username: 'kasir1',
        password: 'password123',
      );
      expect(loggedIn.username, 'kasir1');
      expect(await sessionService.getSessionToken(), isNotNull);
      expect(await sessionService.getActiveCashierId(), loggedIn.id);
      expect(await repository.checkSession(), equals(loggedIn));
    });
  });

  group('AuthBloc', () {
    late _FakeAuthLocalDataSource dataSource;
    late _FakeSecureSessionService sessionService;
    late AuthRepositoryImpl repository;
    late AuthBloc bloc;

    setUp(() {
      dataSource = _FakeAuthLocalDataSource();
      sessionService = _FakeSecureSessionService();
      repository = AuthRepositoryImpl(
        localDataSource: dataSource,
        sessionService: sessionService,
      );
      bloc = AuthBloc(authRepository: repository);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('emits AuthChecking then AuthUnauthenticated when no session exists',
        () async {
      expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthChecking(),
          const AuthUnauthenticated(),
        ]),
      );

      bloc.add(const AuthCheckRequested());
    });

    test(
        'emits AuthRegisterSuccess on register, then AuthAuthenticated on login',
        () async {
      final registerFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthSubmitting(),
          const AuthRegisterSuccess('budi01'),
        ]),
      );

      bloc.add(
        const AuthRegisterSubmitted(
          name: 'Budi',
          username: 'budi01',
          password: 'password123',
        ),
      );
      await registerFuture;

      final loginFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthSubmitting(),
          isA<AuthAuthenticated>(),
        ]),
      );

      bloc.add(
        const AuthLoginSubmitted(
          username: 'budi01',
          password: 'password123',
        ),
      );
      await loginFuture;
    });
  });
}
