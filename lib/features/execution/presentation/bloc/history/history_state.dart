import 'package:equatable/equatable.dart';
import '../../../data/models/step_model.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<StepModel> steps;

  const HistoryLoaded(this.steps);

  @override
  List<Object?> get props => [steps];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
