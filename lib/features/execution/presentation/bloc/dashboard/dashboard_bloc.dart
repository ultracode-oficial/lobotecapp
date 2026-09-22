import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/dashboard_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardUseCase _getDashboardUseCase;

  DashboardBloc({required this._getDashboardUseCase})
      : super(DashboardInitial()) {
    on<FetchDashboardEvent>(_onFetchDashboard);
  }

  Future<void> _onFetchDashboard(
    FetchDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final result = await _getDashboardUseCase();
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (dashboard) => emit(DashboardLoaded(dashboard)),
    );
  }
}
