import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/features/stocks/data/stock_transaction_model.dart';

class StockService {
  final String _baseUrl;
  StockService({required String baseUrl}) : _baseUrl = baseUrl;

  // List all stock transactions (enriched with product/unit/supplier names if backend provides)
  Future<List<StockTransaction>> getTransactions() async {
    final res = await http.get(Uri.parse('$_baseUrl/products/stock/transactions'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      return list.map((e) => StockTransaction.fromJson(e as Map<String, dynamic>)).toList();
    }
    _throw(res, 'Failed to load stock transactions');
  }

  // View a single transaction
  Future<StockTransaction> getTransactionById(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/products/stock/transactions/$id'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : (decoded['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
      return StockTransaction.fromJson(map);
    }
    _throw(res, 'Failed to load stock transaction');
  }

  // Edit a transaction (PATCH)
  Future<void> updateTransaction(int id, Map<String, dynamic> updated) async {
    final body = json.encode(Map<String, dynamic>.from(updated)..removeWhere((k, v) => v == null));
    final res = await http.patch(
      Uri.parse('$_baseUrl/products/stock/transactions/$id'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode != 200) _throw(res, 'Failed to update stock transaction');
  }

  // Delete a transaction
  Future<void> deleteTransaction(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/products/stock/transactions/$id'));
    if (res.statusCode != 200) _throw(res, 'Failed to delete stock transaction');
  }

  Never _throw(http.Response res, String fallback) {
    try {
      final map = json.decode(res.body) as Map<String, dynamic>;
      throw Exception('${map['error'] ?? fallback} (status ${res.statusCode})');
    } catch (_) {
      throw Exception('$fallback (status ${res.statusCode})');
    }
  }
}