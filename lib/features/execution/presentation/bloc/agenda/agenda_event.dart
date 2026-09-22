import 'package:equatable/equatable.dart';

abstract class AgendaEvent extends Equatable {
  const AgendaEvent();

  @override
  List<Object?> get props => [];
}

class FetchAgendaEvent extends AgendaEvent {
  final String dataInicio;
  final String dataFim;
  final String? status;

  const FetchAgendaEvent({
    required this.dataInicio,
    required this.dataFim,
    this.status,
  });

  @override
  List<Object?> get props => [dataInicio, dataFim, status];
}
