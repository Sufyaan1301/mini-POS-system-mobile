part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on SplashScreen to check active cashier session in local storage.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Dispatched when cashier submits the offline login form.
final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

/// Dispatched when cashier submits the offline registration form.
final class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted({
    required this.name,
    required this.username,
    required this.password,
  });

  final String name;
  final String username;
  final String password;

  @override
  List<Object?> get props => [name, username, password];
}

/// Dispatched when cashier logs out.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
