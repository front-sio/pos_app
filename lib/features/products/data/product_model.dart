import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final String? description;

  final double initialQuantity;
  final double quantity;

  final double pricePerQuantity;
  final double? price;

  final String? barcode;

  final int? unitId;
  final String? unitName;

  final int? categoryId;
  final String? categoryName;

  final String? location;
  final double reorderLevel;
  final String? supplier;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed from backend: quantity * price_per_quantity
  // Not stored in DB; returned by API as total_value.
  final double? totalValue;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.initialQuantity,
    required this.quantity,
    required this.pricePerQuantity,
    required this.price,
    required this.barcode,
    required this.unitId,
    required this.unitName,
    required this.categoryId,
    required this.categoryName,
    required this.location,
    required this.reorderLevel,
    required this.supplier,
    required this.createdAt,
    required this.updatedAt,
    required this.totalValue,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double _numToDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int? _toIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    int _toInt(dynamic v) {
      final x = _toIntOrNull(v);
      return x ?? 0;
    }

    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Product(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      initialQuantity: _numToDouble(json['initial_quantity']),
      quantity: _numToDouble(json['quantity']),
      pricePerQuantity: _numToDouble(json['price_per_quantity']),
      price: json['price'] == null ? null : _numToDouble(json['price']),
      barcode: json['barcode']?.toString(),
      unitId: _toIntOrNull(json['unit_id']),
      unitName: json['unit_name']?.toString(),
      categoryId: _toIntOrNull(json['category_id']),
      categoryName: json['category_name']?.toString(),
      location: json['location']?.toString(),
      reorderLevel: _numToDouble(json['reorder_level']),
      supplier: json['supplier']?.toString(),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
      totalValue: json.containsKey('total_value')
          ? _numToDouble(json['total_value'])
          // Fallback compute client-side if backend didn’t include it
          : (_numToDouble(json['quantity']) * _numToDouble(json['price_per_quantity'])),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        initialQuantity,
        quantity,
        pricePerQuantity,
        price,
        barcode,
        unitId,
        unitName,
        categoryId,
        categoryName,
        location,
        reorderLevel,
        supplier,
        createdAt,
        updatedAt,
        totalValue,
      ];
}