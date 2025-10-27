import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/returns/data/return_model.dart';

class ReturnsService {
  final String baseUrl = AppConfig.baseUrl;

  // Caches
  final Map<int, int?> _saleItemToProductId = {};   // saleitemId -> productId
  final Map<int, String?> _productIdToName = {};    // productId  -> productName
  final Map<int, String?> _saleItemNameCache = {};  // saleitemId -> productName (final cache)

  Future<List<ProductReturn>> getAll() async {
    final url = Uri.parse('$baseUrl/returns');
    final res = await http.get(url, headers: const {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('Failed to load returns (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final List rawList = decoded is List ? decoded : (decoded is Map ? (decoded['data'] as List? ?? const []) : const []);
    var list = rawList.map((e) => ProductReturn.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    // Find returns missing name
    final idsNeedingName = <int>{
      for (final r in list)
        if ((r.productName == null || r.productName!.trim().isEmpty) && r.saleitemId > 0) r.saleitemId,
    };

    // Resolve names concurrently
    await Future.wait(idsNeedingName.map(_resolveProductNameForSaleItem));

    // Patch list with resolved names
    list = list
        .map((r) => (r.productName == null || r.productName!.trim().isEmpty)
            ? r.copyWith(productName: _saleItemNameCache[r.saleitemId])
            : r)
        .toList();

    return list;
  }

  Future<void> create({
    required int saleitemId,
    required int quantityReturned,
    String? reason,
  }) async {
    final url = Uri.parse('$baseUrl/returns');
    final res = await http.post(
      url,
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'saleitem_id': saleitemId,
        'quantity_returned': quantityReturned,
        if (reason != null) 'reason': reason,
      }),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create return (${res.statusCode}): ${res.body}');
    }
  }

  // ------------------ Enrichment helpers ------------------

  Future<void> _resolveProductNameForSaleItem(int saleItemId) async {
    if (_saleItemNameCache.containsKey(saleItemId)) return;

    // 1) Resolve product_id from sales-service
    final productId = await _getProductIdForSaleItem(saleItemId);
    if (productId == null || productId <= 0) {
      _saleItemNameCache[saleItemId] = null;
      return;
    }

    // 2) Resolve product name from products-service
    final name = await _getProductName(productId);
    _saleItemNameCache[saleItemId] = (name != null && name.trim().isNotEmpty) ? name.trim() : null;
  }

  Future<int?> _getProductIdForSaleItem(int saleItemId) async {
    if (_saleItemToProductId.containsKey(saleItemId)) {
      return _saleItemToProductId[saleItemId];
    }

    // Canonical route in your sales-service
    final candidates = <Uri>[
      Uri.parse('$baseUrl/sales/items/$saleItemId'),
      // Fallbacks if your gateway exposes alternative routes
      Uri.parse('$baseUrl/saleitems/$saleItemId'),
      Uri.parse('$baseUrl/sale-items/$saleItemId'),
    ];

    for (final uri in candidates) {
      try {
        final r = await http.get(uri, headers: const {'Accept': 'application/json'});
        if (r.statusCode != 200) continue;

        final body = jsonDecode(r.body);
        final map = body is Map<String, dynamic>
            ? (body['data'] is Map ? Map<String, dynamic>.from(body['data']) : body)
            : null;
        if (map == null) continue;

        final pid = _asInt(map['product_id'] ?? map['productId']);
        _saleItemToProductId[saleItemId] = pid > 0 ? pid : null;
        return _saleItemToProductId[saleItemId];
      } catch (_) {
        // try next candidate
      }
    }

    _saleItemToProductId[saleItemId] = null;
    return null;
  }

  Future<String?> _getProductName(int productId) async {
    if (_productIdToName.containsKey(productId)) {
      return _productIdToName[productId];
    }

    // Canonical route in products-service
    final candidates = <Uri>[
      Uri.parse('$baseUrl/products/$productId'),
      // Optional variations if gateway maps differently
      Uri.parse('$baseUrl/product/$productId'),
      Uri.parse('$baseUrl/api/products/$productId'),
    ];

    for (final uri in candidates) {
      try {
        final r = await http.get(uri, headers: const {'Accept': 'application/json'});
        if (r.statusCode != 200) continue;

        final body = jsonDecode(r.body);
        String? pickName(Map<String, dynamic> m) {
          if (m['product_name'] != null) return m['product_name'].toString();
          if (m['productName'] != null) return m['productName'].toString();
          if (m['name'] != null) return m['name'].toString();
          if (m['title'] != null) return m['title'].toString();
          return null;
        }

        String? name;
        if (body is Map<String, dynamic>) {
          name = pickName(body) ?? (body['data'] is Map ? pickName(Map<String, dynamic>.from(body['data'])) : null);
        }

        _productIdToName[productId] = (name != null && name.trim().isNotEmpty) ? name.trim() : null;
        return _productIdToName[productId];
      } catch (_) {
        // try next candidate
      }
    }

    _productIdToName[productId] = null;
    return null;
  }

  // ------------------ Utils ------------------

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}