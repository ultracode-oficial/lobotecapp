import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/checklist_model.dart';
import '../../data/models/equipment_model.dart';
import '../../data/models/step_model.dart';
import '../../data/models/task_model.dart';
import '../repositories/execution_repository.dart';

class GetStepDetailUseCase {
  final ExecutionRepository _repository;
  GetStepDetailUseCase(this._repository);
  Future<Either<Failure, StepModel>> call(int etapaId) =>
      _repository.getStepDetail(etapaId);
}

class PerformCheckInUseCase {
  final ExecutionRepository _repository;
  PerformCheckInUseCase(this._repository);
  Future<Either<Failure, StepModel>> call(
    int etapaId, {
    required double lat,
    required double lng,
  }) =>
      _repository.performCheckIn(etapaId, lat: lat, lng: lng);
}

class UploadSignatureUseCase {
  final ExecutionRepository _repository;
  UploadSignatureUseCase(this._repository);
  Future<Either<Failure, String>> call(int etapaId, String imagePath) =>
      _repository.uploadSignature(etapaId, imagePath);
}

class FinalizeStepUseCase {
  final ExecutionRepository _repository;
  FinalizeStepUseCase(this._repository);
  Future<Either<Failure, Map<String, dynamic>>> call(
    int etapaId, {
    bool confirmRemocaoNaoIniciados = false,
  }) =>
      _repository.finalizeStep(
        etapaId,
        confirmRemocaoNaoIniciados: confirmRemocaoNaoIniciados,
      );
}

class GetEquipmentsUseCase {
  final ExecutionRepository _repository;
  GetEquipmentsUseCase(this._repository);
  Future<Either<Failure, List<EquipmentModel>>> call(int etapaId) =>
      _repository.getEquipments(etapaId);
}

class GetEquipmentDetailUseCase {
  final ExecutionRepository _repository;
  GetEquipmentDetailUseCase(this._repository);
  Future<Either<Failure, EquipmentModel>> call(
    int etapaId,
    int equipamentoServicoId,
  ) =>
      _repository.getEquipmentDetail(etapaId, equipamentoServicoId);
}

class StartEquipmentUseCase {
  final ExecutionRepository _repository;
  StartEquipmentUseCase(this._repository);
  Future<Either<Failure, void>> call(
    int etapaId,
    int equipamentoServicoId,
  ) =>
      _repository.startEquipment(etapaId, equipamentoServicoId);
}

class RegisterEquipmentUseCase {
  final ExecutionRepository _repository;
  RegisterEquipmentUseCase(this._repository);
  Future<Either<Failure, EquipmentModel>> call(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  ) =>
      _repository.registerEquipment(etapaId, equipamentoServicoId, data);
}

class SaveChecklistUseCase {
  final ExecutionRepository _repository;
  SaveChecklistUseCase(this._repository);
  Future<Either<Failure, ChecklistModel>> call(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  ) =>
      _repository.saveChecklist(etapaId, equipamentoServicoId, data);
}

class UploadChecklistPhotoUseCase {
  final ExecutionRepository _repository;
  UploadChecklistPhotoUseCase(this._repository);
  Future<Either<Failure, Map<String, dynamic>>> call(
    int etapaId,
    int equipamentoServicoId, {
    required String tipo,
    required String imagePath,
  }) =>
      _repository.uploadChecklistPhoto(
        etapaId,
        equipamentoServicoId,
        tipo: tipo,
        imagePath: imagePath,
      );
}

class FinalizeEquipmentUseCase {
  final ExecutionRepository _repository;
  FinalizeEquipmentUseCase(this._repository);
  Future<Either<Failure, Map<String, dynamic>>> call(
    int etapaId,
    int equipamentoServicoId, {
    bool confirmPendencias = false,
  }) =>
      _repository.finalizeEquipment(
        etapaId,
        equipamentoServicoId,
        confirmPendencias: confirmPendencias,
      );
}

class ToggleTaskUseCase {
  final ExecutionRepository _repository;
  ToggleTaskUseCase(this._repository);
  Future<Either<Failure, TaskModel>> call(int tarefaId, {String? status}) =>
      _repository.toggleTask(tarefaId, status: status);
}
