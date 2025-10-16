import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';

class PurchaseService {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<Purchase>> getAllPurchases() async {
    final url = Uri.parse('$baseUrl/products/purchases');
    final res = await http.get(url, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => Purchase.fromJson(e as Map<String, dynamic>)).toList();
      }
      debugPrint('[PurchaseService][getAllPurchases] Expected list, got ${decoded.runtimeType}');
      return [];
    } else {
      throw Exception('Failed to load purchases (${res.statusCode}): ${res.body}');
    }
  }

  // Multi-item purchase creation
  // payload:
  // {
  //   supplier_id?: number,
  //   status: 'paid'|'unpaid'|'credited',
  //   paid_amount?: number,
  //   notes?: string,
  //   items: [{product_id, quantity, price_per_unit}]
  // }
  Future<void> createPurchase({
    int? supplierId,
    String status = 'unpaid',
    double? paidAmount,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$baseUrl/products/purchases');

    final payload = <String, dynamic>{
      if (supplierId != null) 'supplier_id': supplierId,
      'status': status,
      if (paidAmount != null) 'paid_amount': paidAmount.toStringAsFixed(2),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items.map((it) {
        return {
          'product_id': it['product_id'],
          'quantity': it['quantity'],
          'price_per_unit': (it['price_per_unit'] as num).toStringAsFixed(2),
        };
      }).toList(),
    };

    final body = jsonEncode(payload);
    debugPrint('[PurchaseService][createPurchase] POST $url');
    debugPrint('[PurchaseService][createPurchase] payload: $body');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body,
    );

    debugPrint('[PurchaseService][createPurchase] status: ${res.statusCode}, response: ${res.body}');

    if (res.statusCode != 201 && res.statusCode != 200) {
      String message = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        } else if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception('Failed to create purchase (${res.statusCode}): $message');
    }
  }

  // Update payment/settlement
  Future<void> updatePurchasePayment({
    required int purchaseId,
    required double paidAmount,
    String? status, // 'paid' | 'unpaid' | 'credited'
  }) async {
    final url = Uri.parse('$baseUrl/products/purchases/$purchaseId/payment');
    final payload = {
      'paid_amount': paidAmount.toStringAsFixed(2),
      if (status != null) 'status': status,
    };
    final res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update purchase payment (${res.statusCode}): ${res.body}');
    }
  }
}