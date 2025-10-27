import 'package:equatable/equatable.dart';

class ProductReturn extends Equatable {
  final int id;
  final int saleitemId;
  final int quantityReturned;
  final String? reason;
  final DateTime returnedAt;
  final String? productName; // parsed or enriched

  const ProductReturn({
    required this.id,
    required this.saleitemId,
    required this.quantityReturned,
    this.reason,
    required this.returnedAt,
    this.productName,
  });

  factory ProductReturn.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) {
        final d = DateTime.tryParse(v);
        return d ?? DateTime.now();
      }
      return DateTime.now();
    }

    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    String? _extractProductName(Map<String, dynamic> j) {
      // 1) direct/flat fields
      if (j['product_name'] != null) return j['product_name'].toString();
      if (j['productName'] != null) return j['productName'].toString();
      // Sometimes APIs put display name in "name" at top-level
      if (j['name'] != null && (j['saleitem'] != null || j['sale_item'] != null || j['saleItem'] != null)) {
        return j['name'].toString();
      }

      // 2) nested product
      final product = j['product'];
      if (product is Map && product['name'] != null) {
        return product['name'].toString();
      }
      if (product is Map && product['title'] != null) {
        return product['title'].toString();
      }

      // 3) nested saleitem -> product
      final saleItem = j['saleitem'] ?? j['sale_item'] ?? j['saleItem'];
      if (saleItem is Map) {
        if (saleItem['product_name'] != null) return saleItem['product_name'].toString();
        if (saleItem['name'] != null) return saleItem['name'].toString();
        final p = saleItem['product'] ?? saleItem['product_detail'] ?? saleItem['productData'];
        if (p is Map) {
          if (p['name'] != null) return p['name'].toString();
          if (p['title'] != null) return p['title'].toString();
        }
      }

      return null;
    }

    final saleItemId = _toInt(
      json['saleitem_id'] ?? json['sale_item_id'] ?? json['saleItemId'] ?? json['saleitemId'] ?? json['sale_item'],
    );

    return ProductReturn(
      id: _toInt(json['id']),
      saleitemId: saleItemId,
      quantityReturned: _toInt(json['quantity_returned'] ?? json['quantityReturned']),
      reason: json['reason']?.toString(),
      returnedAt: _parseDate(json['returned_at'] ?? json['returnedAt']),
      productName: _extractProductName(json),
    );
  }

  ProductReturn copyWith({
    int? id,
    int? saleitemId,
    int? quantityReturned,
    String? reason,
    DateTime? returnedAt,
    String? productName,
  }) {
    return ProductReturn(
      id: id ?? this.id,
      saleitemId: saleitemId ?? this.saleitemId,
      quantityReturned: quantityReturned ?? this.quantityReturned,
      reason: reason ?? this.reason,
      returnedAt: returnedAt ?? this.returnedAt,
      productName: productName ?? this.productName,
    );
  }

  @override
  List<Object?> get props => [id, saleitemId, quantityReturned, reason, returnedAt, productName];
}