import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos_system/features/auth/data/models/cashier_model.dart';
import 'package:mini_pos_system/features/auth/data/repositories/auth_repository.dart';
import 'package:mini_pos_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mini_pos_system/features/auth/presentation/pages/login_page.dart';

class _StubAuthRepository implements AuthRepository {
  @override
  Future<CashierModel?> checkSession() async => null;

  @override
  Future<CashierModel> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<CashierModel> register({
    required String name,
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('LoginPage validates empty username and password',
      (WidgetTester tester) async {
    final bloc = AuthBloc(authRepository: _StubAuthRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const LoginPage(),
        ),
      ),
    );

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Username wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);

    await bloc.close();
  });
}
