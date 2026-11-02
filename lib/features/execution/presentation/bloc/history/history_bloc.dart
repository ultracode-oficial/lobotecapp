import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/history_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetHistoricoUseCase _getHistoricoUseCase;

  HistoryBloc({required this._getHistoricoUseCase})
      : super(HistoryInitial()) {
    on<FetchHistoryEvent>(_onFetchHistory);
  }

  Future<void> _onFetchHistory(
    FetchHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    final result = await _getHistoricoUseCase(
      q: event.q,
      data: event.data,
      perPage: event.perPage,
    );
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (steps) => emit(HistoryLoaded(steps)),
    );
  }
}
