
class ProfitSummary {
  final double revenue;
  final double grossProfit;
  final double netProfit;
  final double profitMargin; // percent
  final int orders;

  ProfitSummary({
    required this.revenue,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.orders,
  });

  factory ProfitSummary.fromJson(Map<String, dynamic> json) {
    double _num(v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    return ProfitSummary(
      revenue: _num(json['revenue']),
      grossProfit: _num(json['gross_profit']),
      netProfit: _num(json['net_profit']),
      profitMargin: _num(json['profit_margin']),
      orders: json['orders'] is num ? (json['orders'] as num).toInt() : int.tryParse(json['orders']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProfitPoint {
  final String label; // YYYY-MM-DD
  final double revenue;
  final double grossProfit;
  final double netProfit;
  final int orders;

  ProfitPoint({
    required this.label,
    required this.revenue,
    required this.grossProfit,
    required this.netProfit,
    required this.orders,
  });

  factory ProfitPoint.fromJson(Map<String, dynamic> json) {
    double _num(v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    return ProfitPoint(
      label: json['label']?.toString() ?? '',
      revenue: _num(json['revenue']),
      grossProfit: _num(json['gross_profit']),
      netProfit: _num(json['net_profit']),
      orders: json['orders'] is num ? (json['orders'] as num).toInt() : int.tryParse(json['orders']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProfitTransaction {
  final int id;
  final DateTime soldAt;
  final double totalAmount;
  final double grossProfit;
  final double netProfit;

  ProfitTransaction({
    required this.id,
    required this.soldAt,
    required this.totalAmount,
    required this.grossProfit,
    required this.netProfit,
  });

  factory ProfitTransaction.fromJson(Map<String, dynamic> json) {
    double _num(v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    DateTime _dt(v) {
      if (v is DateTime) return v;
      final s = v?.toString();
      return DateTime.tryParse(s ?? '') ?? DateTime.now();
    }

    return ProfitTransaction(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      soldAt: _dt(json['sold_at']),
      totalAmount: _num(json['total_amount']),
      grossProfit: _num(json['gross_profit']),
      netProfit: _num(json['net_profit']),
    );
  }
}