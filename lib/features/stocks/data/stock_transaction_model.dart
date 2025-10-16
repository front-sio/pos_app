import 'package:equatable/equatable.dart';

class StockTransaction extends Equatable {
  final int id;
  final int productId;
  final int userId;
  final double amountAdded;
  final double pricePerUnit;
  final double totalCost;
  final DateTime date;

  // Supplier linkage
  final int? supplierId;
  final String? supplierName;

  // Optional denormalized fields if your backend includes them
  final String? productName;
  final String? unitName;

  const StockTransaction({
    required this.id,
    required this.productId,
    required this.userId,
    required this.amountAdded,
    required this.pricePerUnit,
    required this.totalCost,
    required this.date,
    this.supplierId,
    this.supplierName,
    this.productName,
    this.unitName,
  });

  StockTransaction copyWith({
    int? id,
    int? productId,
    int? userId,
    double? amountAdded,
    double? pricePerUnit,
    double? totalCost,
    DateTime? date,
    int? supplierId,
    String? supplierName,
    String? productName,
    String? unitName,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      amountAdded: amountAdded ?? this.amountAdded,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalCost: totalCost ?? this.totalCost,
      date: date ?? this.date,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      productName: productName ?? this.productName,
      unitName: unitName ?? this.unitName,
    );
  }

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      final raw = v.toString();
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    // Some backends return "timestamp", others "date"
    final dynamic dateValue = json.containsKey('timestamp') ? json['timestamp'] : json['date'];

    return StockTransaction(
      id: _toInt(json['id']),
      productId: _toInt(json['product_id']),
      userId: _toInt(json['user_id']),
      amountAdded: _toDouble(json['amount_added']),
      pricePerUnit: _toDouble(json['price_per_unit']),
      totalCost: _toDouble(json['total_cost']),
      date: _toDate(dateValue),
      supplierId: json['supplier_id'] == null ? null : _toInt(json['supplier_id']),
      supplierName: json['supplier_name']?.toString(),
      productName: json['product_name']?.toString(),
      unitName: json['unit_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        userId,
        amountAdded,
        pricePerUnit,
        totalCost,
        date,
        supplierId,
        supplierName,
        productName,
        unitName,
      ];
}