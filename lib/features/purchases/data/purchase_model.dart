import 'package:equatable/equatable.dart';

class PurchaseItem extends Equatable {
  final int id;
  final int productId;
  final int quantity;
  final double pricePerUnit;
  final double totalCost;
  final String? productName;
  final String? unitName;

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalCost,
    this.productName,
    this.unitName,
  });

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: _asInt(json['id'] ?? 0),
      productId: _asInt(json['product_id']),
      quantity: _asInt(json['quantity']),
      pricePerUnit: _asDouble(json['price_per_unit']),
      totalCost: _asDouble(json['total_cost']),
      productName: json['product_name']?.toString(),
      unitName: json['unit_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, productId, quantity, pricePerUnit, totalCost, productName, unitName];
}

class Purchase extends Equatable {
  final int id;
  final int? supplierId;
  final String? supplierName; // if your API returns it later
  final String status; // paid | unpaid | credited
  final double subtotal;
  final double total;
  final double paidAmount;
  final DateTime date;
  final String? notes;
  final List<PurchaseItem> items;

  const Purchase({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.subtotal,
    required this.total,
    required this.paidAmount,
    required this.date,
    required this.items,
    this.notes,
  });

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final List itemsJson = (json['items'] as List?) ?? const [];
    return Purchase(
      id: _asInt(json['id']),
      supplierId: json['supplier_id'] == null ? null : _asInt(json['supplier_id']),
      supplierName: json['supplier_name']?.toString(),
      status: (json['status']?.toString() ?? 'unpaid'),
      subtotal: _asDouble(json['subtotal']),
      total: _asDouble(json['total']),
      paidAmount: _asDouble(json['paid_amount']),
      date: _parseDate(json['date']),
      notes: json['notes']?.toString(),
      items: itemsJson.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  double get dueAmount => total - paidAmount;

  @override
  List<Object?> get props => [id, supplierId, supplierName, status, subtotal, total, paidAmount, date, notes, items];
}