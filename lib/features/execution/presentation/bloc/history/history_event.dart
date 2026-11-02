import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchHistoryEvent extends HistoryEvent {
  final String? q;
  final String? data;
  final int perPage;

  const FetchHistoryEvent({
    this.q,
    this.data,
    this.perPage = 50,
  });

  @override
  List<Object?> get props => [q, data, perPage];
}
