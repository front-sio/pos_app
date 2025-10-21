import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';
import 'package:sales_app/network/auth_http_client.dart';

class CustomerService {
  final String baseUrl;
  final AuthHttpClient _client;

  CustomerService({
    String? baseUrl,
    AuthHttpClient? client,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? AuthHttpClient();

  Uri _u(String path, [Map<String, String>? qp]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: qp);

  Future<List<Customer>> getCustomers({int page = 1, int limit = 20}) async {
    final res = await _client.get(_u('/customers', {'page': '$page', 'limit': '$limit'}));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final List list = body is List ? body : (body['data'] as List? ?? []);
      return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_err(res));
  }

  Future<Customer> getCustomerById(int id) async {
    final res = await _client.get(_u('/customers/$id'));
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(res.body);
      return Customer.fromJson(data);
    }
    throw Exception(_err(res));
  }

  Future<Customer> createCustomer(String name) async {
    final res = await _client.post(
      _u('/customers'),
      body: json.encode({'name': name}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final id = (body['id'] as num?)?.toInt() ?? int.tryParse('${body['id']}') ?? 0;
      return getCustomerById(id);
    }
    throw Exception(_err(res));
  }

  Future<void> updateCustomer(int id, String name) async {
    final res = await _client.put(
      _u('/customers/$id'),
      body: json.encode({'name': name}),
    );
    if (res.statusCode != 200) {
      throw Exception(_err(res));
    }
  }

  Future<void> deleteCustomer(int id) async {
    final res = await _client.delete(_u('/customers/$id'));
    if (res.statusCode != 200) {
      throw Exception(_err(res));
    }
  }

  String _err(http.Response res) {
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['error']?.toString() ?? body['message']?.toString() ?? 'HTTP ${res.statusCode}';
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }
}