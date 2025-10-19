import 'package:sales_app/features/reports/models/report_model.dart';
import 'package:sales_app/features/reports/services/reports_service.dart';

class ReportsRepository {
  final ReportsService service;
  ReportsRepository({required this.service});

  Future<ReportResponse> getDailyReport(DateTime date) => service.fetchDailyReport(date);
  Future<ReportResponse> getMonthlyReport(int year, int month) => service.fetchMonthlyReport(year, month);
  Future<InventoryReport> getInventoryReport({int threshold = 10}) => service.fetchInventoryReport(threshold: threshold);
  Future<FinancialReport> getFinancialReport(int year, int month) => service.fetchFinancialReport(year, month);
  Future<CustomersReport> getCustomersReport(int year, int month) => service.fetchCustomersReport(year, month);
}