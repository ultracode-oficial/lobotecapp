import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/usecases/step_execution_usecases.dart';
import 'step_execution_event.dart';
import 'step_execution_state.dart';

class StepExecutionBloc extends Bloc<StepExecutionEvent, StepExecutionState> {
  final GetStepDetailUseCase _getStepDetailUseCase;
  final PerformCheckInUseCase _performCheckInUseCase;
  final StartEquipmentUseCase _startEquipmentUseCase;
  final ToggleTaskUseCase _toggleTaskUseCase;
  final SaveChecklistUseCase _saveChecklistUseCase;
  final UploadChecklistPhotoUseCase _uploadChecklistPhotoUseCase;
  final UploadSignatureUseCase _uploadSignatureUseCase;
  final FinalizeStepUseCase _finalizeStepUseCase;

  StepExecutionBloc({
    required this._getStepDetailUseCase,
    required this._performCheckInUseCase,
    required this._startEquipmentUseCase,
    required this._toggleTaskUseCase,
    required this._saveChecklistUseCase,
    required this._uploadChecklistPhotoUseCase,
    required this._uploadSignatureUseCase,
    required this._finalizeStepUseCase,
  }) : super(StepExecutionInitial()) {
    on<FetchStepDetailEvent>(_onFetchStepDetail);
    on<PerformCheckInEvent>(_onPerformCheckIn);
    on<StartEquipmentEvent>(_onStartEquipment);
    on<ToggleTaskEvent>(_onToggleTask);
    on<SaveChecklistEvent>(_onSaveChecklist);
    on<UploadChecklistPhotoEvent>(_onUploadChecklistPhoto);
    on<UploadSignatureEvent>(_onUploadSignature);
    on<FinalizeStepEvent>(_onFinalizeStep);
  }

  Future<void> _onFetchStepDetail(
    FetchStepDetailEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    emit(StepExecutionLoading());
    final result = await _getStepDetailUseCase(event.etapaId);
    result.fold(
      (failure) => emit(StepExecutionError(failure.message)),
      (step) => emit(StepExecutionLoaded(step)),
    );
  }

  Future<void> _onPerformCheckIn(
    PerformCheckInEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    emit(StepExecutionLoading());
    final result = await _performCheckInUseCase(
      event.etapaId,
      lat: event.lat,
      lng: event.lng,
    );
    result.fold(
      (failure) => emit(StepExecutionError(failure.message)),
      (step) => emit(StepCheckInSuccess(step)),
    );
  }

  Future<void> _onStartEquipment(
    StartEquipmentEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    final result =
        await _startEquipmentUseCase(event.etapaId, event.eqServicoId);
    result.fold(
      (failure) => emit(StepExecutionError(failure.message)),
      (_) => add(FetchStepDetailEvent(event.etapaId)),
    );
  }

  Future<void> _onToggleTask(
    ToggleTaskEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    final result = await _toggleTaskUseCase(event.tarefaId, status: event.status);
    result.fold(
      (failure) => emit(StepExecutionError(failure.message)),
      (_) => add(FetchStepDetailEvent(event.etapaId)),
    );
  }

  Future<void> _onSaveChecklist(
    SaveChecklistEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    final result = await _saveChecklistUseCase(
      event.etapaId,
      event.eqServicoId,
      event.data,
    );
    result.fold(
      (failure) => emit(StepExecutionError(failure.message)),
      (_) => add(FetchStepDetailEvent(event.etapaId)),
    );
  }

  Future<void> _onUploadChecklistPhoto(
    UploadChecklistPhotoEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    final result = await _uploadChecklistPhotoUseCase(
      event.etapaId,
      event.eqServicoId,
      tipo: event.tipo,
      imagePath: event.imagePath,
    );
    result.fold(
      (failure) => emit(StepExecutionError(failure.message)),
      (_) => add(FetchStepDetailEvent(event.etapaId)),
    );
  }

  Future<void> _onUploadSignature(
    UploadSignatureEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    emit(StepExecutionLoading());
    final result =
        await _uploadSignatureUseCase(event.etapaId, event.imagePath);
    await result.fold(
      (failure) async => emit(StepExecutionError(failure.message)),
      (url) async {
        final stepRes = await _getStepDetailUseCase(event.etapaId);
        stepRes.fold(
          (failure) => emit(StepExecutionError(failure.message)),
          (step) => emit(StepSignatureUploaded(step, url)),
        );
      },
    );
  }

  Future<void> _onFinalizeStep(
    FinalizeStepEvent event,
    Emitter<StepExecutionState> emit,
  ) async {
    emit(StepExecutionLoading());
    final result = await _finalizeStepUseCase(
      event.etapaId,
      confirmRemocaoNaoIniciados: event.confirmRemocaoNaoIniciados,
    );
    result.fold(
      (failure) {
        if (failure is ValidationFailure && failure.errors != null) {
          final code = failure.errors!['code'] as String?;
          if (code == 'CONFIRMATION_REQUIRED') {
            emit(StepConfirmationRequired(
              etapaId: event.etapaId,
              message: failure.message,
              data: failure.errors!,
            ));
            return;
          }
        }
        emit(StepExecutionError(failure.message));
      },
      (data) => emit(StepFinalizedSuccess(
        data['message'] as String? ?? 'Atendimento finalizado com sucesso!',
      )),
    );
  }
}
