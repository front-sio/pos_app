import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
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
        if (d['error'] != null) {
          msg = d['error'].toString();
        } else if (d['message'] != null) {
          msg = d['message'].toString();
        }
      }
    } catch (_) {}
    return Exception('$prefix (${res.statusCode}): $msg');
  }

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<Map<String, dynamic>>> getRawExpenses() async {
    final uri = Uri.parse('$baseUrl/expenses');
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load expenses', res);
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      }
      return const <Map<String, dynamic>>[];
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> getRawExpense(int id) async {
    final uri = Uri.parse('$baseUrl/expenses/$id');
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load expense #$id', res);
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  // Note: we do not require the server to return an id.
  // If create returns 200/201 we treat it as success and return the parsed id when available (else 0).
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

    // Be forgiving about the shape of the response
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        final dynamic idCandidate = decoded['id'] ??
            (data is Map<String, dynamic> ? data['id'] : null) ??
            (data is Map<String, dynamic> ? (data['expense'] is Map ? (data['expense'] as Map)['id'] : null) : null);
        if (idCandidate is num) return idCandidate.toInt();
        final parsed = int.tryParse('${idCandidate ?? ''}');
        return parsed ?? 0; // success but no parseable id
      }
    } catch (_) {
      // Some APIs return empty body on 201; treat as success
    }
    return 0;
  }
}