import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/step_model.dart';
import '../repositories/execution_repository.dart';

class GetHistoricoUseCase {
  final ExecutionRepository _repository;

  GetHistoricoUseCase(this._repository);

  Future<Either<Failure, List<StepModel>>> call({
    String? q,
    String? data,
    int perPage = 50,
  }) =>
      _repository.getHistorico(q: q, data: data, perPage: perPage);
}
