import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

class LoadDailyReport extends ReportsEvent {
  final DateTime date;
  const LoadDailyReport(this.date);
  @override
  List<Object?> get props => [date];
}

class LoadMonthlyReport extends ReportsEvent {
  final int year;
  final int month;
  const LoadMonthlyReport(this.year, this.month);
  @override
  List<Object?> get props => [year, month];
}

class LoadInventoryReport extends ReportsEvent {
  final int threshold;
  const LoadInventoryReport({this.threshold = 10});
  @override
  List<Object?> get props => [threshold];
}

class LoadFinancialReport extends ReportsEvent {
  final int year;
  final int month;
  const LoadFinancialReport(this.year, this.month);
  @override
  List<Object?> get props => [year, month];
}

class LoadCustomersReport extends ReportsEvent {
  final int year;
  final int month;
  const LoadCustomersReport(this.year, this.month);
  @override
  List<Object?> get props => [year, month];
}