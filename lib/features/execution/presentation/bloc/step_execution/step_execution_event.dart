import 'package:equatable/equatable.dart';

abstract class StepExecutionEvent extends Equatable {
  const StepExecutionEvent();

  @override
  List<Object?> get props => [];
}

class FetchStepDetailEvent extends StepExecutionEvent {
  final int etapaId;
  const FetchStepDetailEvent(this.etapaId);

  @override
  List<Object?> get props => [etapaId];
}

class PerformCheckInEvent extends StepExecutionEvent {
  final int etapaId;
  final double lat;
  final double lng;

  const PerformCheckInEvent(this.etapaId, {required this.lat, required this.lng});

  @override
  List<Object?> get props => [etapaId, lat, lng];
}

class StartEquipmentEvent extends StepExecutionEvent {
  final int etapaId;
  final int eqServicoId;

  const StartEquipmentEvent(this.etapaId, this.eqServicoId);

  @override
  List<Object?> get props => [etapaId, eqServicoId];
}

class ToggleTaskEvent extends StepExecutionEvent {
  final int etapaId;
  final int tarefaId;
  final String? status;

  const ToggleTaskEvent(this.etapaId, this.tarefaId, {this.status});

  @override
  List<Object?> get props => [etapaId, tarefaId, status];
}

class SaveChecklistEvent extends StepExecutionEvent {
  final int etapaId;
  final int eqServicoId;
  final Map<String, dynamic> data;

  const SaveChecklistEvent(this.etapaId, this.eqServicoId, this.data);

  @override
  List<Object?> get props => [etapaId, eqServicoId, data];
}

class UploadChecklistPhotoEvent extends StepExecutionEvent {
  final int etapaId;
  final int eqServicoId;
  final String tipo;
  final String imagePath;

  const UploadChecklistPhotoEvent({
    required this.etapaId,
    required this.eqServicoId,
    required this.tipo,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [etapaId, eqServicoId, tipo, imagePath];
}

class UploadSignatureEvent extends StepExecutionEvent {
  final int etapaId;
  final String imagePath;

  const UploadSignatureEvent(this.etapaId, this.imagePath);

  @override
  List<Object?> get props => [etapaId, imagePath];
}

class FinalizeStepEvent extends StepExecutionEvent {
  final int etapaId;
  final bool confirmRemocaoNaoIniciados;

  const FinalizeStepEvent(this.etapaId, {this.confirmRemocaoNaoIniciados = false});

  @override
  List<Object?> get props => [etapaId, confirmRemocaoNaoIniciados];
}
