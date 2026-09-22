import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SendResetCodeUseCase {
  final AuthRepository repository;
  const SendResetCodeUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) {
    return repository.sendResetCode(email);
  }
}

class VerifyResetCodeUseCase {
  final AuthRepository repository;
  const VerifyResetCodeUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String code,
  }) {
    return repository.verifyResetCode(email: email, code: code);
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;
  const ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) {
    return repository.resetPassword(
      email: email,
      code: code,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
