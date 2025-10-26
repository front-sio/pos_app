import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/network/auth_http_client.dart';
import 'package:sales_app/utils/data/unit_model.dart';


class UnitService {
  final String baseUrl;
  final AuthHttpClient _client;

  UnitService({String? baseUrl, AuthHttpClient? client})
      : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? AuthHttpClient();

  Map<String, String> get _json => {'Content-Type': 'application/json', 'Accept': 'application/json'};

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

  Future<List<ProductUnit>> getUnits() async {
    final uri = Uri.parse('$baseUrl/products/units');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load units', res);
    final decoded = jsonDecode(res.body);
    final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list.map((e) => ProductUnit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductUnit> createUnit(String name) async {
    final uri = Uri.parse('$baseUrl/products/units');
    final res = await _client.post(uri, headers: _json, body: jsonEncode({'name': name}));
    if (res.statusCode != 201 && res.statusCode != 200) throw _err('Failed to create unit', res);
    final d = jsonDecode(res.body);
    if (d is Map && d['id'] != null) {
      return ProductUnit(id: (d['id'] is int ? d['id'] : int.tryParse('${d['id']}') ?? 0), name: name);
    }
    return ProductUnit(id: 0, name: name);
  }

  Future<void> deleteUnit(int id) async {
    final uri = Uri.parse('$baseUrl/products/units/$id');
    final res = await _client.delete(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to delete unit', res);
  }
}