import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecases.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/verify_mfa_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Execution
import '../../features/execution/data/datasources/execution_remote_datasource.dart';
import '../../features/execution/data/repositories/execution_repository_impl.dart';
import '../../features/execution/domain/repositories/execution_repository.dart';
import '../../features/execution/domain/usecases/agenda_usecases.dart';
import '../../features/execution/domain/usecases/dashboard_usecase.dart';
import '../../features/execution/domain/usecases/service_orders_usecases.dart';
import '../../features/execution/domain/usecases/step_execution_usecases.dart';
import '../../features/execution/presentation/bloc/agenda/agenda_bloc.dart';
import '../../features/execution/presentation/bloc/dashboard/dashboard_bloc.dart';
import '../../features/execution/presentation/bloc/service_orders/service_orders_bloc.dart';
import '../../features/execution/presentation/bloc/step_execution/step_execution_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core / Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(storage: getIt<FlutterSecureStorage>()),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(storage: getIt<SecureStorageService>()),
  );

  // --- Auth ---
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(client: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      dataSource: getIt<AuthRemoteDataSource>(),
      storage: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => VerifyMfaUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => ChangePasswordUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SendResetCodeUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => VerifyResetCodeUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => ResetPasswordUseCase(getIt<AuthRepository>()));

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      verifyMfaUseCase: getIt<VerifyMfaUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      changePasswordUseCase: getIt<ChangePasswordUseCase>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );

  // --- Execution ---
  getIt.registerLazySingleton<ExecutionRemoteDataSource>(
    () => ExecutionRemoteDataSourceImpl(client: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ExecutionRepository>(
    () => ExecutionRepositoryImpl(
      dataSource: getIt<ExecutionRemoteDataSource>(),
    ),
  );

  // Execution Use Cases
  getIt.registerLazySingleton(() => GetDashboardUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => GetServiceOrdersUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => GetServiceOrderDetailUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => FinalizeServiceOrderUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => GetAgendaUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => GetAgendaOcupacaoUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => GetStepDetailUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => PerformCheckInUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => UploadSignatureUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => FinalizeStepUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => GetEquipmentsUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => GetEquipmentDetailUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => StartEquipmentUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => RegisterEquipmentUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => SaveChecklistUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => UploadChecklistPhotoUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => FinalizeEquipmentUseCase(getIt<ExecutionRepository>()));
  getIt.registerLazySingleton(() => ToggleTaskUseCase(getIt<ExecutionRepository>()));

  // Execution BLoCs
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(getDashboardUseCase: getIt<GetDashboardUseCase>()),
  );

  getIt.registerFactory<ServiceOrdersBloc>(
    () => ServiceOrdersBloc(
      getServiceOrdersUseCase: getIt<GetServiceOrdersUseCase>(),
      getServiceOrderDetailUseCase: getIt<GetServiceOrderDetailUseCase>(),
      finalizeServiceOrderUseCase: getIt<FinalizeServiceOrderUseCase>(),
    ),
  );

  getIt.registerFactory<StepExecutionBloc>(
    () => StepExecutionBloc(
      getStepDetailUseCase: getIt<GetStepDetailUseCase>(),
      performCheckInUseCase: getIt<PerformCheckInUseCase>(),
      startEquipmentUseCase: getIt<StartEquipmentUseCase>(),
      toggleTaskUseCase: getIt<ToggleTaskUseCase>(),
      saveChecklistUseCase: getIt<SaveChecklistUseCase>(),
      uploadChecklistPhotoUseCase: getIt<UploadChecklistPhotoUseCase>(),
      uploadSignatureUseCase: getIt<UploadSignatureUseCase>(),
      finalizeStepUseCase: getIt<FinalizeStepUseCase>(),
    ),
  );

  getIt.registerFactory<AgendaBloc>(
    () => AgendaBloc(getAgendaUseCase: getIt<GetAgendaUseCase>()),
  );
}
