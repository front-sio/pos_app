import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/network/auth_http_client.dart';
import 'package:sales_app/features/categories/data/category_model.dart';

class CategoryService {
  final String baseUrl;
  final AuthHttpClient _client;

  CategoryService({String? baseUrl, AuthHttpClient? client})
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

  Future<List<Category>> getCategories() async {
    final uri = Uri.parse('$baseUrl/products/categories');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to load categories', res);
    final decoded = jsonDecode(res.body);
    final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory(String name) async {
    final uri = Uri.parse('$baseUrl/products/categories');
    final res = await _client.post(uri, headers: _json, body: jsonEncode({'name': name}));
    if (res.statusCode != 201 && res.statusCode != 200) throw _err('Failed to create category', res);
    // Some backends return {id, message}; fetch list again to stay consistent
    // But we attempt to decode single row if provided
    final d = jsonDecode(res.body);
    if (d is Map && d['id'] != null) {
      return Category(id: (d['id'] is int ? d['id'] : int.tryParse('${d['id']}') ?? 0), name: name);
    }
    // Fallback: return with temp id 0; UI will reload
    return Category(id: 0, name: name);
  }

  Future<void> deleteCategory(int id) async {
    final uri = Uri.parse('$baseUrl/products/categories/$id');
    final res = await _client.delete(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw _err('Failed to delete category', res);
  }
}