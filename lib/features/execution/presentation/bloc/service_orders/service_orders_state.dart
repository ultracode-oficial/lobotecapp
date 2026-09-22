import 'package:equatable/equatable.dart';
import '../../../data/models/service_order_model.dart';

abstract class ServiceOrdersState extends Equatable {
  const ServiceOrdersState();

  @override
  List<Object?> get props => [];
}

class ServiceOrdersInitial extends ServiceOrdersState {}

class ServiceOrdersLoading extends ServiceOrdersState {}

class ServiceOrdersLoaded extends ServiceOrdersState {
  final List<ServiceOrderModel> orders;

  const ServiceOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class ServiceOrderDetailLoaded extends ServiceOrdersState {
  final ServiceOrderModel order;

  const ServiceOrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class ServiceOrderFinalizedSuccess extends ServiceOrdersState {
  final int orderId;
  final String message;

  const ServiceOrderFinalizedSuccess(this.orderId, this.message);

  @override
  List<Object?> get props => [orderId, message];
}

class ServiceOrdersError extends ServiceOrdersState {
  final String message;
  final String? code;

  const ServiceOrdersError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}
