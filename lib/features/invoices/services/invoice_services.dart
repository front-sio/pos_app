import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';

class InvoiceService {
  final String baseUrl;
  final http.Client _client;

  InvoiceService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? http.Client();

  // GET /invoices
  Future<List<Invoice>> getInvoices() async {
    final uri = Uri.parse('$baseUrl/invoices');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to load invoices (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded.map<Invoice>((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <Invoice>[];
  }

  // GET /invoices/:id
  Future<Invoice> getInvoice(int id) async {
    final uri = Uri.parse('$baseUrl/invoices/$id');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to load invoice #$id (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return Invoice.fromJson(decoded);
    }
    throw Exception('Invalid invoice payload for #$id');
  }

  // GET /invoices/:id/payments
  Future<List<Payment>> getPayments(int invoiceId) async {
    final uri = Uri.parse('$baseUrl/invoices/$invoiceId/payments');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to load payments for invoice #$invoiceId (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded.map<Payment>((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <Payment>[];
  }

  // POST /invoices  Body: { customer_id, total_amount, status, sales: [ids] }
  Future<int> createInvoice({
    required int customerId,
    required double totalAmount,
    required String status,
    required List<int> saleIds,
  }) async {
    final uri = Uri.parse('$baseUrl/invoices');
    final body = jsonEncode({
      'customer_id': customerId,
      'total_amount': totalAmount.toStringAsFixed(2),
      'status': status,
      'sales': saleIds,
    });
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body,
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create invoice (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final id = decoded['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
    }
    // Some APIs return the full resource; try to read id from there.
    final maybe = decoded is Map<String, dynamic> ? decoded['invoice_id'] : null;
    if (maybe is int) return maybe;
    throw Exception('Create invoice succeeded but could not parse id');
  }

  // POST /invoices/:id/payments  Body: { amount }
  Future<void> addPayment({required int invoiceId, required double amount}) async {
    final uri = Uri.parse('$baseUrl/invoices/$invoiceId/payments');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'amount': amount.toStringAsFixed(2)}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to add payment (${res.statusCode}): ${res.body}');
    }
  }

  // Optional helper used by tiles: GET /invoices/by-sale/:saleId -> 200 with invoice or 404 if none
  Future<Invoice?> getInvoiceBySale(int saleId) async {
    final uri = Uri.parse('$baseUrl/invoices/by-sale/$saleId');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch invoice by sale ($saleId): ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return Invoice.fromJson(decoded);
    }
    return null;
  }
}