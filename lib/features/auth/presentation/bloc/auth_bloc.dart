import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/verify_mfa_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final VerifyMfaUseCase _verifyMfaUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final AuthRepository _authRepository;

  AuthBloc({
    required this._loginUseCase,
    required this._verifyMfaUseCase,
    required this._getCurrentUserUseCase,
    required this._logoutUseCase,
    required this._changePasswordUseCase,
    required this._authRepository,
  }) : super(AuthInitial()) {
    on<AuthCheckSessionRequested>(_onCheckSession);
    on<AuthLoginRequested>(_onLogin);
    on<AuthMfaVerifyRequested>(_onMfaVerify);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthChangePasswordRequested>(_onChangePassword);
  }

  Future<void> _onCheckSession(
    AuthCheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isActive = await _authRepository.isSessionActive();

    if (!isActive) {
      emit(AuthUnauthenticated());
      return;
    }

    emit(AuthLoading());
    final result = await _getCurrentUserUseCase();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user.changePasswordRequired) {
          emit(AuthPasswordChangeRequired(user: user));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      },
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _loginUseCase(
      LoginParams(login: event.login, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (loginResult) {
        if (loginResult is LoginMfaPending) {
          emit(AuthMfaPending(mfaToken: loginResult.mfaToken));
        } else if (loginResult is LoginSuccess) {
          if (loginResult.user.changePasswordRequired) {
            emit(AuthPasswordChangeRequired(user: loginResult.user));
          } else {
            emit(AuthAuthenticated(user: loginResult.user));
          }
        }
      },
    );
  }

  Future<void> _onMfaVerify(
    AuthMfaVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _verifyMfaUseCase(event.code);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (loginResult) {
        if (loginResult.user.changePasswordRequired) {
          emit(AuthPasswordChangeRequired(user: loginResult.user));
        } else {
          emit(AuthAuthenticated(user: loginResult.user));
        }
      },
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(AuthUnauthenticated());
  }

  Future<void> _onChangePassword(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        newPasswordConfirmation: event.newPasswordConfirmation,
      ),
    );

    await result.fold(
      (failure) async => emit(AuthError(message: failure.message)),
      (_) async {
        final userResult = await _getCurrentUserUseCase();
        userResult.fold(
          (failure) => emit(AuthError(message: failure.message)),
          (user) => emit(AuthAuthenticated(user: user)),
        );
      },
    );
  }
}
