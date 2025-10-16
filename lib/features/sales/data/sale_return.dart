import 'package:flutter/foundation.dart';

@immutable
class SaleReturn {
  final int id;
  final int saleItemId;
  final int quantityReturned;
  final String? reason;
  final DateTime returnedAt;

  const SaleReturn({
    required this.id,
    required this.saleItemId,
    required this.quantityReturned,
    required this.returnedAt,
    this.reason,
  });

  factory SaleReturn.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) {
        final d = DateTime.tryParse(v);
        return d ?? DateTime.now();
      }
      return DateTime.now();
    }

    return SaleReturn(
      id: _toInt(json['id']),
      saleItemId: _toInt(json['saleitem_id']),
      quantityReturned: _toInt(json['quantity_returned']),
      reason: json['reason']?.toString(),
      returnedAt: _parseDate(json['returned_at']),
    );
  }
}