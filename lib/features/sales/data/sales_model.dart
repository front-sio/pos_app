import 'package:flutter/foundation.dart';
import 'sale_item.dart';

@immutable
class Sale {
  final int id;
  final int? customerId;
  final DateTime soldAt;
  final double? totalAmount;
  final List<SaleItem> items;
  final InvoiceStatus? invoiceStatus;

  const Sale({
    required this.id,
    this.customerId,
    required this.soldAt,
    this.totalAmount,
    this.items = const [],
    this.invoiceStatus,
  });

  static DateTime _parseDate(dynamic v) {
    try {
      if (v == null) return DateTime.now();
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return DateTime.now();
        final parsed = DateTime.tryParse(s);
        if (parsed != null) return parsed;
        return DateTime.now();
      }
      if (v is int) {
        final isMs = v > 1000000000000;
        final ms = isMs ? v : v * 1000;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  static double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: _asInt(json['id']),
      customerId: json['customer_id'] == null ? null : _asInt(json['customer_id']),
      soldAt: _parseDate(json['sold_at']),
      totalAmount: _asDoubleOrNull(json['total_amount']),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      invoiceStatus: json['invoice'] != null
          ? InvoiceStatus.fromJson(json['invoice'] as Map<String, dynamic>)
          : null,
    );
  }

  Sale copyWith({
    int? id,
    int? customerId,
    DateTime? soldAt,
    double? totalAmount,
    List<SaleItem>? items,
    InvoiceStatus? invoiceStatus,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      soldAt: soldAt ?? this.soldAt,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale &&
           other.id == id &&
           other.customerId == customerId &&
           other.soldAt == soldAt &&
           other.totalAmount == totalAmount &&
           listEquals(other.items, items) &&
           other.invoiceStatus == invoiceStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      soldAt,
      totalAmount,
      Object.hashAll(items),
      invoiceStatus,
    );
  }
}

class InvoiceStatus {
  final int invoiceId;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final bool isPaid;

  const InvoiceStatus({
    required this.invoiceId,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.isPaid,
  });

  factory InvoiceStatus.fromJson(Map<String, dynamic> json) {
    return InvoiceStatus(
      invoiceId: json['invoice_id'] as int,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      dueAmount: (json['due_amount'] as num).toDouble(),
      isPaid: json['is_paid'] as bool,
    );
  }
}