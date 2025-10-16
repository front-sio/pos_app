import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/features/suppliers/data/supplier_model.dart';

class SupplierService {
  final String baseUrl;
  SupplierService({required this.baseUrl});

  Uri _u(String path, [Map<String, String>? qp]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: qp);

  Future<List<Supplier>> getSuppliers({int page = 1, int limit = 20}) async {
    final res = await http.get(_u('/suppliers', {'page': '$page', 'limit': '$limit'}));
    if (res.statusCode == 200) {
      final List list = json.decode(res.body);
      return list.map((e) => Supplier.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_err(res));
  }

  Future<Supplier> getSupplierById(int id) async {
    final res = await http.get(_u('/suppliers/$id'));
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(res.body);
      return Supplier.fromJson(data);
    }
    throw Exception(_err(res));
  }

  Future<Supplier> createSupplier(Map<String, dynamic> payload) async {
    final clean = Map<String, dynamic>.from(payload)..removeWhere((k, v) => v == null);
    final res = await http.post(
      _u('/suppliers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(clean),
    );
    if (res.statusCode == 201) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      final id = (map['id'] as num).toInt();
      return getSupplierById(id);
    }
    throw Exception(_err(res));
  }

  Future<void> updateSupplier(int id, Map<String, dynamic> payload) async {
    final clean = Map<String, dynamic>.from(payload)..removeWhere((k, v) => v == null);
    final res = await http.patch(
      _u('/suppliers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(clean),
    );
    if (res.statusCode != 200) {
      throw Exception(_err(res));
    }
  }

  Future<void> deleteSupplier(int id) async {
    final res = await http.delete(_u('/suppliers/$id'));
    if (res.statusCode != 200) {
      throw Exception(_err(res));
    }
  }

  String _err(http.Response res) {
    try {
      final body = json.decode(res.body);
      return body['error']?.toString() ?? 'HTTP ${res.statusCode}';
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }
}