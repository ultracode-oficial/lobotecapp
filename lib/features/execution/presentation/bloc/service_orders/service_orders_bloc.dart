import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/service_orders_usecases.dart';
import 'service_orders_event.dart';
import 'service_orders_state.dart';

class ServiceOrdersBloc extends Bloc<ServiceOrdersEvent, ServiceOrdersState> {
  final GetServiceOrdersUseCase _getServiceOrdersUseCase;
  final GetServiceOrderDetailUseCase _getServiceOrderDetailUseCase;
  final FinalizeServiceOrderUseCase _finalizeServiceOrderUseCase;

  ServiceOrdersBloc({
    required this._getServiceOrdersUseCase,
    required this._getServiceOrderDetailUseCase,
    required this._finalizeServiceOrderUseCase,
  }) : super(ServiceOrdersInitial()) {
    on<FetchServiceOrdersEvent>(_onFetchServiceOrders);
    on<FetchServiceOrderDetailEvent>(_onFetchServiceOrderDetail);
    on<FinalizeServiceOrderEvent>(_onFinalizeServiceOrder);
  }

  Future<void> _onFetchServiceOrders(
    FetchServiceOrdersEvent event,
    Emitter<ServiceOrdersState> emit,
  ) async {
    emit(ServiceOrdersLoading());
    final result = await _getServiceOrdersUseCase(
      status: event.status,
      dataInicio: event.dataInicio,
      dataFim: event.dataFim,
    );
    result.fold(
      (failure) => emit(ServiceOrdersError(failure.message)),
      (orders) => emit(ServiceOrdersLoaded(orders)),
    );
  }

  Future<void> _onFetchServiceOrderDetail(
    FetchServiceOrderDetailEvent event,
    Emitter<ServiceOrdersState> emit,
  ) async {
    emit(ServiceOrdersLoading());
    final result = await _getServiceOrderDetailUseCase(event.id);
    result.fold(
      (failure) => emit(ServiceOrdersError(failure.message)),
      (order) => emit(ServiceOrderDetailLoaded(order)),
    );
  }

  Future<void> _onFinalizeServiceOrder(
    FinalizeServiceOrderEvent event,
    Emitter<ServiceOrdersState> emit,
  ) async {
    emit(ServiceOrdersLoading());
    final result = await _finalizeServiceOrderUseCase(event.id);
    result.fold(
      (failure) => emit(ServiceOrdersError(failure.message)),
      (res) => emit(ServiceOrderFinalizedSuccess(
        event.id,
        res['message'] as String? ?? 'Ordem de Serviço finalizada com sucesso!',
      )),
    );
  }
}
