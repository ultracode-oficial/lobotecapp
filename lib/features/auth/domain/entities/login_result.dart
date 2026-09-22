import 'package:equatable/equatable.dart';
import '../entities/user_entity.dart';

abstract class LoginResult extends Equatable {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  final String accessToken;
  final UserEntity user;

  const LoginSuccess({required this.accessToken, required this.user});

  @override
  List<Object?> get props => [accessToken, user];
}

class LoginMfaPending extends LoginResult {
  final String mfaToken;

  const LoginMfaPending({required this.mfaToken});

  @override
  List<Object?> get props => [mfaToken];
}
