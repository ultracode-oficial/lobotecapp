import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/step_model.dart';
import '../repositories/execution_repository.dart';

class GetAgendaUseCase {
  final ExecutionRepository _repository;

  GetAgendaUseCase(this._repository);

  Future<Either<Failure, List<StepModel>>> call({
    required String dataInicio,
    required String dataFim,
    String? status,
  }) =>
      _repository.getAgenda(
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: status,
      );
}

class GetAgendaOcupacaoUseCase {
  final ExecutionRepository _repository;

  GetAgendaOcupacaoUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String dataInicio,
    required String dataFim,
  }) =>
      _repository.getAgendaOcupacao(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
}
