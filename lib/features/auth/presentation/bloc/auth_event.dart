import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckSessionRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String login;
  final String password;

  const AuthLoginRequested({required this.login, required this.password});

  @override
  List<Object?> get props => [login, password];
}

class AuthMfaVerifyRequested extends AuthEvent {
  final String code;

  const AuthMfaVerifyRequested({required this.code});

  @override
  List<Object?> get props => [code];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  const AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, newPasswordConfirmation];
}
