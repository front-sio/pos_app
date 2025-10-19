import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/sales/data/new_sale_dto.dart';
import 'package:sales_app/features/sales/data/sales_model.dart';
import 'package:sales_app/features/sales/data/sale_return.dart';

class SalesService {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<Sale>> getAllSales() async {
    final url = Uri.parse('$baseUrl/sales');
    final res = await http.get(url, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
      }
      debugPrint('[SalesService][getAllSales] Expected list, got ${decoded.runtimeType}');
      return [];
    }
    throw Exception('Failed to load sales (${res.statusCode}): ${res.body}');
  }

  Future<Sale> createSale(NewSaleDto saleDto) async {
    final createUrl = Uri.parse('$baseUrl/sales');
    final body = jsonEncode(saleDto.toJson());
    final res = await http.post(
      createUrl,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body,
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw _asMeaningfulException('Create sale failed', res);
    }

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}

    if (json != null && json.containsKey('items')) {
      return Sale.fromJson(json);
    }

    final saleId = _extractId(json) ?? 0;
    return Sale(
      id: saleId,
      customerId: saleDto.customerId,
      soldAt: DateTime.now(),
      totalAmount: saleDto.items.fold<double>(0, (s, it) => s + it.totalSalePrice),
    );
  }

  Future<Sale?> getSaleById(int id) async {
    final url = Uri.parse('$baseUrl/sales/$id');
    final res = await http.get(url, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return Sale.fromJson(decoded);
      }
      return null;
    } else if (res.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to load sale #$id (${res.statusCode})');
  }

  Future<InvoiceStatus?> getInvoiceBySaleId(int saleId) async {
    final url = Uri.parse('$baseUrl/invoices/by-sale/$saleId');
    final res = await http.get(url, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return InvoiceStatus.fromJson(decoded);
      }
      return null;
    } else if (res.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to fetch invoice for sale #$saleId (${res.statusCode})');
  }

  Future<List<SaleReturn>> getReturnsBySaleId(int saleId) async {
    final url = Uri.parse('$baseUrl/returns/by-sale/$saleId');
    final res = await http.get(url, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => SaleReturn.fromJson(e as Map<String, dynamic>)).toList();
      }
      debugPrint('[SalesService][getReturnsBySaleId] Expected list, got ${decoded.runtimeType}');
      return [];
    } else if (res.statusCode == 404) {
      return [];
    }
    throw Exception('Failed to load returns for sale #$saleId (${res.statusCode}): ${res.body}');
  }

  Future<void> createReturn({
    required int saleItemId,
    required int quantityReturned,
    String? reason,
  }) async {
    final url = Uri.parse('$baseUrl/returns');
    final payload = jsonEncode({
      'saleitem_id': saleItemId,
      'quantity_returned': quantityReturned,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: payload,
    );

    if (res.statusCode != 201) {
      throw _asMeaningfulException('Create return failed', res);
    }
  }

  Exception _asMeaningfulException(String prefix, http.Response res) {
    String message = res.body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        if (decoded['error'] != null) message = decoded['error'].toString();
        else if (decoded['message'] != null) message = decoded['message'].toString();
      }
    } catch (_) {}
    return Exception('$prefix (${res.statusCode}): $message');
  }

  int? _extractId(Map<String, dynamic>? json) {
    if (json == null) return null;
    final v = json['id'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}