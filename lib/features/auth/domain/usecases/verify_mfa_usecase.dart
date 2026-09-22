import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/login_result.dart';
import '../repositories/auth_repository.dart';

class VerifyMfaUseCase {
  final AuthRepository repository;
  const VerifyMfaUseCase(this.repository);

  Future<Either<Failure, LoginSuccess>> call(String code) {
    return repository.verifyMfa(code);
  }
}
