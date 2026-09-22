import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/dashboard_model.dart';
import '../repositories/execution_repository.dart';

class GetDashboardUseCase {
  final ExecutionRepository _repository;

  GetDashboardUseCase(this._repository);

  Future<Either<Failure, DashboardModel>> call() => _repository.getDashboard();
}
