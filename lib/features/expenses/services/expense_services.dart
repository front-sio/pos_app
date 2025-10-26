import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/expenses/data/expense_model.dart';
import 'package:sales_app/network/auth_http_client.dart';

class ExpenseService {
  final String baseUrl;
  final AuthHttpClient _client;

  ExpenseService({
    String? baseUrl,
    AuthHttpClient? client,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? AuthHttpClient();

  Exception _err(String prefix, http.Response res) {
    String msg = res.body;
    try {
      final d = jsonDecode(res.body);
      if (d is Map) {
        if (d['error'] != null) msg = d['error'].toString();
        else if (d['message'] != null) msg = d['message'].toString();
      }
    } catch (_) {}
    return Exception('$prefix (${res.statusCode}): $msg');
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<Expense>> getExpenses() async {
    final uri = Uri.parse('$baseUrl/expenses');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load expenses', res);
    final decoded = jsonDecode(res.body);
    final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Expense> getExpense(int id) async {
    final uri = Uri.parse('$baseUrl/expenses/$id');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load expense #$id', res);
    final decoded = jsonDecode(res.body);
    return Expense.fromJson(decoded as Map<String, dynamic>);
  }

  Future<int> createExpense({
    required String description,
    required double amount,
    required DateTime dateIncurred,
  }) async {
    final uri = Uri.parse('$baseUrl/expenses');
    final body = jsonEncode({
      'description': description.trim(),
      'amount': double.parse(amount.toStringAsFixed(2)),
      'date_incurred': dateIncurred.toIso8601String().split('T').first,
    });
    final res = await _client.post(uri, headers: _jsonHeaders, body: body);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw _err('Failed to create expense', res);
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final id = decoded['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
    }
    throw Exception('Create expense succeeded but could not parse id');
  }
}