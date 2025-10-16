import 'package:flutter/foundation.dart';

@immutable
class SaleItem {
  // Sale item primary key from backend (required to correlate returns)
  final int? id;

  final int productId;
  final double quantitySold;
  final double salePricePerQuantity;
  final double totalSalePrice;

  const SaleItem({
    required this.productId,
    required this.quantitySold,
    required this.salePricePerQuantity,
    required this.totalSalePrice,
    this.id,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    double _numToDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return SaleItem(
      id: json['id'] == null ? null : _toInt(json['id']), // IMPORTANT
      productId: _toInt(json['product_id']),
      quantitySold: _numToDouble(json['quantity_sold'] ?? json['quantity']),
      salePricePerQuantity: _numToDouble(json['sale_price_per_quantity'] ?? json['unit_price']),
      totalSalePrice: _numToDouble(json['total_sale_price'] ?? json['total_price']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        'product_id': productId,
        'quantity_sold': quantitySold,
        'sale_price_per_quantity': salePricePerQuantity,
        'total_sale_price': totalSalePrice,
        // aliases
        'quantity': quantitySold,
        'unit_price': salePricePerQuantity,
        'total_price': totalSalePrice,
      };

  @override
  bool operator ==(Object other) {
    return other is SaleItem &&
        other.id == id &&
        other.productId == productId &&
        other.quantitySold == quantitySold &&
        other.salePricePerQuantity == salePricePerQuantity &&
        other.totalSalePrice == totalSalePrice;
  }

  @override
  int get hashCode => Object.hash(id, productId, quantitySold, salePricePerQuantity, totalSalePrice);
}