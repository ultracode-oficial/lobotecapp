import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/login_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, LoginResult>> login({
    required String login,
    required String password,
  });

  Future<Either<Failure, LoginSuccess>> verifyMfa(String code);

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });

  Future<Either<Failure, void>> sendResetCode(String email);

  Future<Either<Failure, void>> verifyResetCode({
    required String email,
    required String code,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  });

  Future<bool> isSessionActive();
}
