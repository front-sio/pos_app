import 'package:equatable/equatable.dart';

class ProfitEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfit extends ProfitEvent {
  final String period; // e.g., 'Today', 'This Week', 'This Month', 'Last 3 Months', 'Custom Range'
  final String view;   // 'Daily' | 'Weekly' | 'Monthly'
  final DateTime? from;
  final DateTime? to;

  LoadProfit({required this.period, required this.view, this.from, this.to});

  @override
  List<Object?> get props => [period, view, from, to];
}

class ChangePeriod extends ProfitEvent {
  final String period;
  ChangePeriod(this.period);
  @override
  List<Object?> get props => [period];
}

class ChangeView extends ProfitEvent {
  final String view;
  ChangeView(this.view);
  @override
  List<Object?> get props => [view];
}

class RefreshProfit extends ProfitEvent {}