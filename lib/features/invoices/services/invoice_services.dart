import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';
import 'package:sales_app/network/auth_http_client.dart';

class InvoiceService {
  final String baseUrl;
  final AuthHttpClient _client;

  InvoiceService({
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

  Future<List<Invoice>> getInvoices() async {
    final uri = Uri.parse('$baseUrl/invoices');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load invoices', res);
    final decoded = jsonDecode(res.body);
    final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Invoice> getInvoice(int id) async {
    final uri = Uri.parse('$baseUrl/invoices/$id');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load invoice #$id', res);
    final decoded = jsonDecode(res.body);
    return Invoice.fromJson(decoded as Map<String, dynamic>);
  }

  Future<List<Payment>> getPayments(int invoiceId) async {
    final uri = Uri.parse('$baseUrl/invoices/$invoiceId/payments');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load payments', res);
    final decoded = jsonDecode(res.body);
    final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> createInvoice({
    required int customerId,
    required double totalAmount,
    required String status,
    required List<int> saleIds,
  }) async {
    final uri = Uri.parse('$baseUrl/invoices');
    final body = jsonEncode({
      'customer_id': customerId,
      'total_amount': double.parse(totalAmount.toStringAsFixed(2)),
      'status': status,
      'sales': saleIds,
    });
    final res = await _client.post(uri, headers: _jsonHeaders, body: body);
    if (res.statusCode != 201 && res.statusCode != 200) throw _err('Failed to create invoice', res);

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final id = decoded['id'] ?? decoded['invoice_id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
    }
    throw Exception('Create invoice succeeded but could not parse id');
  }

  Future<void> addPayment({required int invoiceId, required double amount}) async {
    final uri = Uri.parse('$baseUrl/invoices/$invoiceId/payments');
    final payload = jsonEncode({'amount': double.parse(amount.toStringAsFixed(2))});
    final res = await _client.post(uri, headers: _jsonHeaders, body: payload);
    if (res.statusCode != 201 && res.statusCode != 200) throw _err('Failed to add payment', res);
  }

  Future<Invoice?> getInvoiceBySale(int saleId) async {
    final uri = Uri.parse('$baseUrl/invoices/by-sale/$saleId');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw _err('Failed to fetch invoice by sale', res);
    final decoded = jsonDecode(res.body);
    return Invoice.fromJson(decoded as Map<String, dynamic>);
  }
}