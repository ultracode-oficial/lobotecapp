import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/checklist_model.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/equipment_model.dart';
import '../../data/models/service_order_model.dart';
import '../../data/models/step_model.dart';
import '../../data/models/task_model.dart';

abstract class ExecutionRepository {
  Future<Either<Failure, DashboardModel>> getDashboard();

  Future<Either<Failure, List<ServiceOrderModel>>> getServiceOrders({
    String? status,
    String? dataInicio,
    String? dataFim,
    int? perPage,
  });

  Future<Either<Failure, ServiceOrderModel>> getServiceOrderDetail(int id);

  Future<Either<Failure, Map<String, dynamic>>> finalizeServiceOrder(int id);

  Future<Either<Failure, List<StepModel>>> getAgenda({
    required String dataInicio,
    required String dataFim,
    String? status,
  });

  Future<Either<Failure, Map<String, dynamic>>> getAgendaOcupacao({
    required String dataInicio,
    required String dataFim,
  });

  Future<Either<Failure, StepModel>> getStepDetail(int etapaId);

  Future<Either<Failure, StepModel>> performCheckIn(
    int etapaId, {
    required double lat,
    required double lng,
  });

  Future<Either<Failure, String>> uploadSignature(
    int etapaId,
    String imagePath,
  );

  Future<Either<Failure, Map<String, dynamic>>> finalizeStep(
    int etapaId, {
    bool confirmRemocaoNaoIniciados = false,
  });

  Future<Either<Failure, List<EquipmentModel>>> getEquipments(int etapaId);

  Future<Either<Failure, EquipmentModel>> getEquipmentDetail(
    int etapaId,
    int equipamentoServicoId,
  );

  Future<Either<Failure, void>> startEquipment(
    int etapaId,
    int equipamentoServicoId,
  );

  Future<Either<Failure, EquipmentModel>> registerEquipment(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ChecklistModel>> saveChecklist(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, Map<String, dynamic>>> uploadChecklistPhoto(
    int etapaId,
    int equipamentoServicoId, {
    required String tipo,
    required String imagePath,
  });

  Future<Either<Failure, Map<String, dynamic>>> finalizeEquipment(
    int etapaId,
    int equipamentoServicoId, {
    bool confirmPendencias = false,
  });

  Future<Either<Failure, TaskModel>> toggleTask(
    int tarefaId, {
    String? status,
  });
}
