// HTTP client for reports-service. Exposes methods for each UI tab.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/reports/models/report_model.dart';

class ReportsService {
  final String baseUrl;
  final http.Client _http;

  ReportsService({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _http = httpClient ?? http.Client();

  Uri _uri(String path, [Map<String, String>? qp]) {
    final uri = Uri.parse(baseUrl + path);
    if (qp != null) return uri.replace(queryParameters: qp);
    return uri;
  }

  Future<ReportResponse> fetchDailyReport(DateTime date) async {
    final dateStr = date.toUtc().toIso8601String().split('T').first;
    final uri = _uri('/reports/daily', {'date': dateStr});
    final res = await _http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('Failed to fetch daily report (${res.statusCode}): ${res.body}');
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
    return ReportResponse.fromDailyJson(json);
  }

  Future<ReportResponse> fetchMonthlyReport(int year, int month) async {
    final uri = _uri('/reports/monthly', {'year': year.toString(), 'month': month.toString()});
    final res = await _http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('Failed to fetch monthly report (${res.statusCode}): ${res.body}');
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
    return ReportResponse.fromMonthlyJson(json);
  }

  Future<InventoryReport> fetchInventoryReport({int threshold = 10}) async {
    final uri = _uri('/reports/inventory', {'threshold': threshold.toString()});
    final res = await _http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('Failed to fetch inventory report (${res.statusCode}): ${res.body}');
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
    return InventoryReport.fromJson(json);
  }

  Future<FinancialReport> fetchFinancialReport(int year, int month) async {
    final uri = _uri('/reports/financial', {'year': year.toString(), 'month': month.toString()});
    final res = await _http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('Failed to fetch financial report (${res.statusCode}): ${res.body}');
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
    return FinancialReport.fromJson(json);
  }

  Future<CustomersReport> fetchCustomersReport(int year, int month) async {
    final uri = _uri('/reports/customers', {'year': year.toString(), 'month': month.toString()});
    final res = await _http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('Failed to fetch customers report (${res.statusCode}): ${res.body}');
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
    return CustomersReport.fromJson(json);
  }

  void dispose() {
    _http.close();
  }
}