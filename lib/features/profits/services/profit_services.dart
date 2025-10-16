import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/profits/data/profit_models.dart';

class ProfitService {
  final String baseUrl = AppConfig.baseUrl;

  Future<ProfitSummary> getSummary({required DateTime from, required DateTime to}) async {
    final uri = Uri.parse('$baseUrl/sales/profit/summary').replace(queryParameters: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to load summary: ${res.body}');
    }
    final Map<String, dynamic> jsonMap = jsonDecode(res.body);
    return ProfitSummary.fromJson(jsonMap);
    }

  Future<List<ProfitPoint>> getTimeline({
    required String view, // 'daily' | 'weekly' | 'monthly'
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('$baseUrl/sales/profit/timeline').replace(queryParameters: {
      'view': view,
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to load timeline: ${res.body}');
    }
    final List list = jsonDecode(res.body);
    return list.map((e) => ProfitPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProfitTransaction>> getTransactions({int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/sales/profit/transactions').replace(queryParameters: {
      'limit': '$limit',
    });
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to load transactions: ${res.body}');
    }
    final List list = jsonDecode(res.body);
    return list.map((e) => ProfitTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }
}