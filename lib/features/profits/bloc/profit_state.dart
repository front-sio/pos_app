import 'package:equatable/equatable.dart';
import 'package:sales_app/features/profits/data/profit_models.dart';

class ProfitState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfitInitial extends ProfitState {}

class ProfitLoading extends ProfitState {}

class ProfitLoaded extends ProfitState {
  final String period;
  final String view;
  final DateTime from;
  final DateTime to;
  final ProfitSummary summary;
  final List<ProfitPoint> timeline;
  final List<ProfitTransaction> transactions;

  ProfitLoaded({
    required this.period,
    required this.view,
    required this.from,
    required this.to,
    required this.summary,
    required this.timeline,
    required this.transactions,
  });

  ProfitLoaded copyWith({
    String? period,
    String? view,
    DateTime? from,
    DateTime? to,
    ProfitSummary? summary,
    List<ProfitPoint>? timeline,
    List<ProfitTransaction>? transactions,
  }) {
    return ProfitLoaded(
      period: period ?? this.period,
      view: view ?? this.view,
      from: from ?? this.from,
      to: to ?? this.to,
      summary: summary ?? this.summary,
      timeline: timeline ?? this.timeline,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  List<Object?> get props => [period, view, from, to, summary, timeline, transactions];
}

class ProfitError extends ProfitState {
  final String message;
  ProfitError(this.message);

  @override
  List<Object?> get props => [message];
}