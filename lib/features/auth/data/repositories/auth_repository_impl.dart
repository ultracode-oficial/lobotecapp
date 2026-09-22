import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final SecureStorageService _storage;

  const AuthRepositoryImpl({
    required this._dataSource,
    required this._storage,
  });

  @override
  Future<Either<Failure, LoginResult>> login({
    required String login,
    required String password,
  }) async {
    try {
      final data = await _dataSource.login(login: login, password: password);

      if (data['status'] == 'requires_mfa') {
        final mfaToken = data['mfa_token'] as String;
        await _storage.saveToken(mfaToken);
        return Right(LoginMfaPending(mfaToken: mfaToken));
      }

      final token = data['access_token'] as String;
      await _storage.saveToken(token);

      final userModel = UserModel.fromLoginJson(data);
      final user = data['user'] as Map<String, dynamic>;
      final changeRequired = user['change_password_required'] == true || user['change_password_required'] == 1;

      UserEntity userEntity;
      try {
        final fullUser = await _dataSource.getCurrentUser();
        userEntity = fullUser.toEntity();
      } catch (_) {
        userEntity = userModel.toEntity();
      }

      return Right(LoginSuccess(
        accessToken: token,
        user: changeRequired
            ? UserEntity(
                id: userEntity.id,
                name: userEntity.name,
                email: userEntity.email,
                cpf: userEntity.cpf,
                phone: userEntity.phone,
                photo: userEntity.photo,
                bio: userEntity.bio,
                mfaEnabled: userEntity.mfaEnabled,
                mfaRequired: userEntity.mfaRequired,
                changePasswordRequired: true,
                isDeveloper: userEntity.isDeveloper,
                roles: userEntity.roles,
                permissions: userEntity.permissions,
              )
            : userEntity,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, LoginSuccess>> verifyMfa(String code) async {
    try {
      final mfaToken = await _storage.getToken() ?? '';
      final data = await _dataSource.verifyMfa(code: code, mfaToken: mfaToken);

      final token = data['access_token'] as String;
      await _storage.saveToken(token);

      final fullUser = await _dataSource.getCurrentUser();
      return Right(LoginSuccess(accessToken: token, user: fullUser.toEntity()));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final model = await _dataSource.getCurrentUser();
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _dataSource.logout();
    } catch (_) {
    } finally {
      await _storage.deleteAll();
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> sendResetCode(String email) async {
    try {
      await _dataSource.sendResetCode(email);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await _dataSource.verifyResetCode(email: email, code: code);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dataSource.resetPassword(
        email: email,
        code: code,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<bool> isSessionActive() async {
    return _storage.hasToken();
  }
}
