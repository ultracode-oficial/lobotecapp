import 'package:equatable/equatable.dart';
import '../../../data/models/step_model.dart';

abstract class AgendaState extends Equatable {
  const AgendaState();

  @override
  List<Object?> get props => [];
}

class AgendaInitial extends AgendaState {}

class AgendaLoading extends AgendaState {}

class AgendaLoaded extends AgendaState {
  final List<StepModel> steps;

  const AgendaLoaded(this.steps);

  @override
  List<Object?> get props => [steps];
}

class AgendaError extends AgendaState {
  final String message;

  const AgendaError(this.message);

  @override
  List<Object?> get props => [message];
}
