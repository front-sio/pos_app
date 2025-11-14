import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final int id;
  final int customerId;
  final String status; // 'paid' | 'unpaid' | 'credited'
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.customerId,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.createdAt,
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

  static DateTime _asDate(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final totalAmt = _asDouble(json['total_amount']);
    final paidAmt = _asDouble(json['paid_amount']);
    final dueAmt = _asDouble(json['due_amount']);
    
    return Invoice(
      id: _asInt(json['id']),
      customerId: _asInt(json['customer_id']),
      status: (json['status']?.toString() ?? 'unpaid').toLowerCase(),
      totalAmount: totalAmt,
      paidAmount: paidAmt,
      dueAmount: dueAmt > 0 ? dueAmt : (totalAmt - paidAmt).clamp(0, double.infinity),
      createdAt: _asDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, customerId, status, totalAmount, paidAmount, dueAmount, createdAt];
}

class Payment extends Equatable {
  final int id;
  final int invoiceId;
  final double amount;
  final DateTime paidAt;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paidAt,
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

  static DateTime _asDate(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _asInt(json['id']),
      invoiceId: _asInt(json['invoice_id']),
      amount: _asDouble(json['amount']),
      paidAt: _asDate(json['paid_at']),
    );
  }

  @override
  List<Object?> get props => [id, invoiceId, amount, paidAt];
}

class InvoiceSummary extends Equatable {
  final int invoiceId;
  final String status; // 'paid' | 'unpaid'
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final bool isPaid;

  const InvoiceSummary({
    required this.invoiceId,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.isPaid,
  });

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      invoiceId: _asInt(json['invoice_id'] ?? json['id']),
      status: (json['status']?.toString() ?? 'unpaid').toLowerCase(),
      totalAmount: _asDouble(json['total_amount']),
      paidAmount: _asDouble(json['paid_amount']),
      dueAmount: _asDouble(json['due_amount']),
      isPaid: json['is_paid'] == true || (json['status']?.toString().toLowerCase() == 'paid'),
    );
  }

  @override
  List<Object?> get props => [invoiceId, status, totalAmount, paidAmount, dueAmount, isPaid];
}