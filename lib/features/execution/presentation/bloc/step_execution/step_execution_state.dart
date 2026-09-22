import 'package:equatable/equatable.dart';
import '../../../data/models/step_model.dart';

abstract class StepExecutionState extends Equatable {
  const StepExecutionState();

  @override
  List<Object?> get props => [];
}

class StepExecutionInitial extends StepExecutionState {}

class StepExecutionLoading extends StepExecutionState {}

class StepExecutionLoaded extends StepExecutionState {
  final StepModel step;

  const StepExecutionLoaded(this.step);

  @override
  List<Object?> get props => [step];
}

class StepCheckInSuccess extends StepExecutionState {
  final StepModel step;

  const StepCheckInSuccess(this.step);

  @override
  List<Object?> get props => [step];
}

class StepSignatureUploaded extends StepExecutionState {
  final StepModel step;
  final String signatureUrl;

  const StepSignatureUploaded(this.step, this.signatureUrl);

  @override
  List<Object?> get props => [step, signatureUrl];
}

class StepConfirmationRequired extends StepExecutionState {
  final int etapaId;
  final String message;
  final Map<String, dynamic> data;

  const StepConfirmationRequired({
    required this.etapaId,
    required this.message,
    required this.data,
  });

  @override
  List<Object?> get props => [etapaId, message, data];
}

class StepFinalizedSuccess extends StepExecutionState {
  final String message;

  const StepFinalizedSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class StepExecutionError extends StepExecutionState {
  final String message;
  final String? code;

  const StepExecutionError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}
