import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/features/customers/data/customer_model.dart';

class CustomerService {
  final String baseUrl;
  CustomerService({required this.baseUrl});

  Uri _u(String path, [Map<String, String>? qp]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: qp);

  Future<List<Customer>> getCustomers({int page = 1, int limit = 20}) async {
    final res = await http.get(_u('/customers', {
      'page': '$page',
      'limit': '$limit',
    }));
    if (res.statusCode == 200) {
      final List list = json.decode(res.body);
      return list
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_err(res));
  }

  Future<Customer> getCustomerById(int id) async {
    final res = await http.get(_u('/customers/$id'));
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(res.body);
      return Customer.fromJson(data);
    }
    throw Exception(_err(res));
  }

  Future<Customer> createCustomer(String name) async {
    final payload = {'name': name};
    final res = await http.post(
      _u('/customers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (res.statusCode == 201) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final id = (body['id'] as num).toInt();
      return getCustomerById(id);
    }
    throw Exception(_err(res));
  }

  // Backend uses PUT for update
  Future<void> updateCustomer(int id, String name) async {
    final res = await http.put(
      _u('/customers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    if (res.statusCode != 200) {
      throw Exception(_err(res));
    }
  }

  Future<void> deleteCustomer(int id) async {
    final res = await http.delete(_u('/customers/$id'));
    if (res.statusCode != 200) {
      throw Exception(_err(res));
    }
  }

  String _err(http.Response res) {
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['error']?.toString() ?? 'HTTP ${res.statusCode}';
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }
}