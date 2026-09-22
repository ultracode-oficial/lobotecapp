import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/execution_repository.dart';
import '../datasources/execution_remote_datasource.dart';
import '../models/checklist_model.dart';
import '../models/dashboard_model.dart';
import '../models/equipment_model.dart';
import '../models/service_order_model.dart';
import '../models/step_model.dart';
import '../models/task_model.dart';

class ExecutionRepositoryImpl implements ExecutionRepository {
  final ExecutionRemoteDataSource _dataSource;

  ExecutionRepositoryImpl({required this._dataSource});

  Future<Either<Failure, T>> _execute<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DashboardModel>> getDashboard() =>
      _execute(() => _dataSource.getDashboard());

  @override
  Future<Either<Failure, List<ServiceOrderModel>>> getServiceOrders({
    String? status,
    String? dataInicio,
    String? dataFim,
    int? perPage,
  }) =>
      _execute(() => _dataSource.getServiceOrders(
            status: status,
            dataInicio: dataInicio,
            dataFim: dataFim,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, ServiceOrderModel>> getServiceOrderDetail(int id) =>
      _execute(() => _dataSource.getServiceOrderDetail(id));

  @override
  Future<Either<Failure, Map<String, dynamic>>> finalizeServiceOrder(int id) =>
      _execute(() => _dataSource.finalizeServiceOrder(id));

  @override
  Future<Either<Failure, List<StepModel>>> getAgenda({
    required String dataInicio,
    required String dataFim,
    String? status,
  }) =>
      _execute(() => _dataSource.getAgenda(
            dataInicio: dataInicio,
            dataFim: dataFim,
            status: status,
          ));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAgendaOcupacao({
    required String dataInicio,
    required String dataFim,
  }) =>
      _execute(() => _dataSource.getAgendaOcupacao(
            dataInicio: dataInicio,
            dataFim: dataFim,
          ));

  @override
  Future<Either<Failure, StepModel>> getStepDetail(int etapaId) =>
      _execute(() => _dataSource.getStepDetail(etapaId));

  @override
  Future<Either<Failure, StepModel>> performCheckIn(
    int etapaId, {
    required double lat,
    required double lng,
  }) =>
      _execute(() => _dataSource.performCheckIn(etapaId, lat: lat, lng: lng));

  @override
  Future<Either<Failure, String>> uploadSignature(
    int etapaId,
    String imagePath,
  ) =>
      _execute(() => _dataSource.uploadSignature(etapaId, imagePath));

  @override
  Future<Either<Failure, Map<String, dynamic>>> finalizeStep(
    int etapaId, {
    bool confirmRemocaoNaoIniciados = false,
  }) =>
      _execute(() => _dataSource.finalizeStep(
            etapaId,
            confirmRemocaoNaoIniciados: confirmRemocaoNaoIniciados,
          ));

  @override
  Future<Either<Failure, List<EquipmentModel>>> getEquipments(int etapaId) =>
      _execute(() => _dataSource.getEquipments(etapaId));

  @override
  Future<Either<Failure, EquipmentModel>> getEquipmentDetail(
    int etapaId,
    int equipamentoServicoId,
  ) =>
      _execute(() => _dataSource.getEquipmentDetail(
            etapaId,
            equipamentoServicoId,
          ));

  @override
  Future<Either<Failure, void>> startEquipment(
    int etapaId,
    int equipamentoServicoId,
  ) =>
      _execute(() => _dataSource.startEquipment(
            etapaId,
            equipamentoServicoId,
          ));

  @override
  Future<Either<Failure, EquipmentModel>> registerEquipment(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  ) =>
      _execute(() => _dataSource.registerEquipment(
            etapaId,
            equipamentoServicoId,
            data,
          ));

  @override
  Future<Either<Failure, ChecklistModel>> saveChecklist(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  ) =>
      _execute(() => _dataSource.saveChecklist(
            etapaId,
            equipamentoServicoId,
            data,
          ));

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadChecklistPhoto(
    int etapaId,
    int equipamentoServicoId, {
    required String tipo,
    required String imagePath,
  }) =>
      _execute(() => _dataSource.uploadChecklistPhoto(
            etapaId,
            equipamentoServicoId,
            tipo: tipo,
            imagePath: imagePath,
          ));

  @override
  Future<Either<Failure, Map<String, dynamic>>> finalizeEquipment(
    int etapaId,
    int equipamentoServicoId, {
    bool confirmPendencias = false,
  }) =>
      _execute(() => _dataSource.finalizeEquipment(
            etapaId,
            equipamentoServicoId,
            confirmPendencias: confirmPendencias,
          ));

  @override
  Future<Either<Failure, TaskModel>> toggleTask(
    int tarefaId, {
    String? status,
  }) =>
      _execute(() => _dataSource.toggleTask(tarefaId, status: status));
}
