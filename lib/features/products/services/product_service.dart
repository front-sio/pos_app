import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/data/unit_model.dart';
import 'package:sales_app/features/products/data/category_model.dart';
import 'package:sales_app/network/authed_client.dart';


// Simple DTOs for select lists
class UnitOption {
  final int id;
  final String name;
  UnitOption({required this.id, required this.name});
  factory UnitOption.fromJson(Map<String, dynamic> json) =>
      UnitOption(id: json['id'] as int, name: (json['name'] ?? '').toString());
}

class CategoryOption {
  final int id;
  final String name;
  CategoryOption({required this.id, required this.name});
  factory CategoryOption.fromJson(Map<String, dynamic> json) =>
      CategoryOption(id: json['id'] as int, name: (json['name'] ?? '').toString());
}

class SupplierOption {
  final int id;
  final String name;
  SupplierOption({required this.id, required this.name});
  factory SupplierOption.fromJson(Map<String, dynamic> json) =>
      SupplierOption(id: json['id'] as int, name: (json['name'] ?? '').toString());
}

class ProductService {
  final String _baseUrl;
  final http.Client _client;

  ProductService({required String baseUrl, AuthedClient? client})
      : _baseUrl = baseUrl,
        _client = client ?? AuthedClient();

  // ---------------- Products ----------------
  Future<List<Product>> getProducts({int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$_baseUrl/products').replace(queryParameters: {
      'page': '$page',
      'limit': '$limit',
    });

    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to load products: ${body['error'] ?? res.statusCode}');
  }

  Future<Product> getProductById(int productId) async {
    final res = await _client.get(Uri.parse('$_baseUrl/products/$productId'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final Map<String, dynamic> data =
          decoded is Map<String, dynamic> ? decoded : (decoded['data'] as Map<String, dynamic>);
      return Product.fromJson(data);
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to get product: ${body['error'] ?? res.statusCode}');
  }

  Future<Product> addProduct(Map<String, dynamic> productData) async {
    final clean = Map<String, dynamic>.from(productData)..removeWhere((k, v) => v == null);
    final res = await _client.post(
      Uri.parse('$_baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(clean),
    );
    if (res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final id = (data['id'] as num).toInt();
      return getProductById(id);
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to add product: ${body['error'] ?? res.statusCode}');
  }

  // Backend uses PATCH for update
  Future<void> updateProduct(int productId, Map<String, dynamic> updatedData) async {
    final clean = Map<String, dynamic>.from(updatedData)..removeWhere((k, v) => v == null);
    final res = await _client.patch(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(clean),
    );
    if (res.statusCode != 200) {
      final body = _decodeSafe(res.body);
      throw Exception('Failed to update product: ${body['error'] ?? res.statusCode}');
    }
  }

  Future<void> deleteProduct(int productId) async {
    final res = await _client.delete(Uri.parse('$_baseUrl/products/$productId'));
    if (res.statusCode != 200) {
      final body = _decodeSafe(res.body);
      throw Exception('Failed to delete product: ${body['error'] ?? res.statusCode}');
    }
  }

  // UPDATED: add supplierId (optional) for backend linkage
  Future<void> addStock({
    required int productId,
    required double amount,
    required double pricePerUnit,
    required int userId,
    int? supplierId,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount,
      'price_per_unit': pricePerUnit,
      'user_id': userId,
      'product_id': productId,
      if (supplierId != null) 'supplier_id': supplierId,
    };
    final res = await _client.post(
      Uri.parse('$_baseUrl/products/$productId/add-stock'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (res.statusCode != 201) {
      final body = _decodeSafe(res.body);
      throw Exception('Failed to add stock: ${body['error'] ?? res.statusCode}');
    }
  }

  // ---------------- Meta (Units, Categories, Suppliers) ----------------
  Future<List<UnitOption>> getUnits() async {
    final res = await _client.get(Uri.parse('$_baseUrl/products/units'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      return list.map((e) => UnitOption.fromJson(e as Map<String, dynamic>)).toList();
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to load units: ${body['error'] ?? res.statusCode}');
  }

  Future<List<CategoryOption>> getCategories() async {
    final res = await _client.get(Uri.parse('$_baseUrl/products/categories'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      return list.map((e) => CategoryOption.fromJson(e as Map<String, dynamic>)).toList();
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to load categories: ${body['error'] ?? res.statusCode}');
  }

  Future<List<SupplierOption>> getSuppliers() async {
    final res = await _client.get(Uri.parse('$_baseUrl/suppliers'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      return list.map((e) => SupplierOption.fromJson(e as Map<String, dynamic>)).toList();
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to load suppliers: ${body['error'] ?? res.statusCode}');
  }

  // Full entities (useful for management screens/overlays)
  Future<List<UnitModel>> getUnitsFull() async {
    final res = await _client.get(Uri.parse('$_baseUrl/products/units'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      return list.map((e) => UnitModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to load units: ${body['error'] ?? res.statusCode}');
  }

  Future<UnitModel> createUnit({required String name, String? description}) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/products/units'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, if (description != null) 'description': description}),
    );
    if (res.statusCode == 201) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      final id = (map['id'] as num).toInt();
      return getUnitById(id);
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to create unit: ${body['error'] ?? res.statusCode}');
  }

  Future<UnitModel> getUnitById(int id) async {
    final res = await _client.get(Uri.parse('$_baseUrl/products/units/$id'));
    if (res.statusCode == 200) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      return UnitModel.fromJson(map);
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to get unit: ${body['error'] ?? res.statusCode}');
  }

  Future<void> updateUnit(int id, {String? name, String? description}) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    final res = await _client.patch(
      Uri.parse('$_baseUrl/products/units/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (res.statusCode != 200) {
      final body = _decodeSafe(res.body);
      throw Exception('Failed to update unit: ${body['error'] ?? res.statusCode}');
    }
  }

  Future<void> deleteUnit(int id) async {
    final res = await _client.delete(Uri.parse('$_baseUrl/products/units/$id'));
    if (res.statusCode != 200) {
      final body = _decodeSafe(res.body);
      throw Exception('Failed to delete unit: ${body['error'] ?? res.statusCode}');
    }
  }

  Future<List<CategoryModel>> getCategoriesFull() async {
    final res = await _client.get(Uri.parse('$_baseUrl/products/categories'));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final List list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to load categories: ${body['error'] ?? res.statusCode}');
  }

  Future<CategoryModel> createCategory({required String name, String? description}) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/products/categories'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, if (description != null) 'description': description}),
    );
    if (res.statusCode == 201) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      final id = (map['id'] as num).toInt();
      return getCategoryById(id);
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to create category: ${body['error'] ?? res.statusCode}');
  }

  Future<CategoryModel> getCategoryById(int id) async {
    final res = await _client.get(Uri.parse('$_baseUrl/products/categories/$id'));
    if (res.statusCode == 200) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      return CategoryModel.fromJson(map);
    }
    final body = _decodeSafe(res.body);
    throw Exception('Failed to get category: ${body['error'] ?? res.statusCode}');
  }

  Future<void> updateCategory(int id, {String? name, String? description}) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    final res = await _client.patch(
      Uri.parse('$_baseUrl/products/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (res.statusCode != 200) {
      final body = _decodeSafe(res.body);
      throw Exception('Failed to update category: ${body['error'] ?? res.statusCode}');
    }
  }

  Future<void> deleteCategory(int id) async {
    final res = await _client.delete(Uri.parse('$_baseUrl/products/categories/$id'));
    if (res.statusCode != 200) {
      final body = _decodeSafe(res.body);
      throw Exception('Failed to delete category: ${body['error'] ?? res.statusCode}');
    }
  }

  Map<String, dynamic> _decodeSafe(String s) {
    try {
      return json.decode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
