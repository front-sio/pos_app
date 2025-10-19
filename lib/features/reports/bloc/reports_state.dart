import 'package:equatable/equatable.dart';
import 'package:sales_app/features/reports/models/report_model.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Sales reports
class SalesReportLoaded extends ReportsState {
  final ReportResponse report;
  const SalesReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

// Inventory
class InventoryReportLoaded extends ReportsState {
  final InventoryReport report;
  const InventoryReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

// Financial
class FinancialReportLoaded extends ReportsState {
  final FinancialReport report;
  const FinancialReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

// Customers
class CustomersReportLoaded extends ReportsState {
  final CustomersReport report;
  const CustomersReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}