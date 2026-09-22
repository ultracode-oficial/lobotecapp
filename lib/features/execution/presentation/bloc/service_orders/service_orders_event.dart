import 'package:equatable/equatable.dart';

abstract class ServiceOrdersEvent extends Equatable {
  const ServiceOrdersEvent();

  @override
  List<Object?> get props => [];
}

class FetchServiceOrdersEvent extends ServiceOrdersEvent {
  final String? status;
  final String? dataInicio;
  final String? dataFim;

  const FetchServiceOrdersEvent({
    this.status,
    this.dataInicio,
    this.dataFim,
  });

  @override
  List<Object?> get props => [status, dataInicio, dataFim];
}

class FetchServiceOrderDetailEvent extends ServiceOrdersEvent {
  final int id;
  const FetchServiceOrderDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class FinalizeServiceOrderEvent extends ServiceOrdersEvent {
  final int id;
  const FinalizeServiceOrderEvent(this.id);

  @override
  List<Object?> get props => [id];
}
