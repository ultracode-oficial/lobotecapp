import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/service_order_model.dart';
import '../repositories/execution_repository.dart';

class GetServiceOrdersUseCase {
  final ExecutionRepository _repository;

  GetServiceOrdersUseCase(this._repository);

  Future<Either<Failure, List<ServiceOrderModel>>> call({
    String? status,
    String? dataInicio,
    String? dataFim,
    int? perPage,
  }) =>
      _repository.getServiceOrders(
        status: status,
        dataInicio: dataInicio,
        dataFim: dataFim,
        perPage: perPage,
      );
}

class GetServiceOrderDetailUseCase {
  final ExecutionRepository _repository;

  GetServiceOrderDetailUseCase(this._repository);

  Future<Either<Failure, ServiceOrderModel>> call(int id) =>
      _repository.getServiceOrderDetail(id);
}

class FinalizeServiceOrderUseCase {
  final ExecutionRepository _repository;

  FinalizeServiceOrderUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call(int id) =>
      _repository.finalizeServiceOrder(id);
}
