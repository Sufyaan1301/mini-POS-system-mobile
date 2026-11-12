part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthChecking extends AuthState {
  const AuthChecking();
}

final class AuthSubmitting extends AuthState {
  const AuthSubmitting();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.cashier);

  final CashierModel cashier;

  @override
  List<Object?> get props => [cashier];
}

final class AuthRegisterSuccess extends AuthState {
  const AuthRegisterSuccess(this.username);

  final String username;

  @override
  List<Object?> get props => [username];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
