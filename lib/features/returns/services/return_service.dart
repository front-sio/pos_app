import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/returns/data/return_model.dart';

class ReturnsService {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<ProductReturn>> getAll() async {
    final url = Uri.parse('$baseUrl/returns');
    final res = await http.get(url, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => ProductReturn.fromJson(e)).toList();
      }
      return [];
    }
    throw Exception('Failed to load returns (${res.statusCode}): ${res.body}');
  }

  Future<void> create({
    required int saleitemId,
    required int quantityReturned,
    String? reason,
  }) async {
    final url = Uri.parse('$baseUrl/returns');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'saleitem_id': saleitemId,
        'quantity_returned': quantityReturned,
        'reason': reason,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to create return (${res.statusCode}): ${res.body}');
    }
  }
}