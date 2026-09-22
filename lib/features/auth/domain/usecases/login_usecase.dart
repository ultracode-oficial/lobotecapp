import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/login_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  const LoginUseCase(this.repository);

  Future<Either<Failure, LoginResult>> call(LoginParams params) {
    return repository.login(login: params.login, password: params.password);
  }
}

class LoginParams extends Equatable {
  final String login;
  final String password;

  const LoginParams({required this.login, required this.password});

  @override
  List<Object?> get props => [login, password];
}
