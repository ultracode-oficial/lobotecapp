import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/agenda_usecases.dart';
import 'agenda_event.dart';
import 'agenda_state.dart';

class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  final GetAgendaUseCase _getAgendaUseCase;

  AgendaBloc({required this._getAgendaUseCase})
      : super(AgendaInitial()) {
    on<FetchAgendaEvent>(_onFetchAgenda);
  }

  Future<void> _onFetchAgenda(
    FetchAgendaEvent event,
    Emitter<AgendaState> emit,
  ) async {
    emit(AgendaLoading());
    final result = await _getAgendaUseCase(
      dataInicio: event.dataInicio,
      dataFim: event.dataFim,
      status: event.status,
    );
    result.fold(
      (failure) => emit(AgendaError(failure.message)),
      (steps) => emit(AgendaLoaded(steps)),
    );
  }
}
