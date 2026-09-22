import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;
  const ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(ChangePasswordParams params) {
    return repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
      newPasswordConfirmation: params.newPasswordConfirmation,
    );
  }
}

class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, newPasswordConfirmation];
}
