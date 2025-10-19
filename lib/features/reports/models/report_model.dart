// Unified report models used by the Reports feature.
// This file replaces separate model files and adds types for inventory/financial/customers reports.

import 'package:flutter/foundation.dart';

@immutable
class TopProduct {
  final int productId;
  final double revenue;
  final double quantity;

  const TopProduct({required this.productId, required this.revenue, required this.quantity});

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is num) return v.toInt();
      return 0;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return TopProduct(
      productId: _toInt(json['productId'] ?? json['product_id']),
      revenue: _toDouble(json['revenue']),
      quantity: _toDouble(json['quantity']),
    );
  }
}

@immutable
class DailyBucket {
  final String date;
  final double revenue;
  final double cost;
  final double grossProfit;
  final int orders;

  const DailyBucket({
    required this.date,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.orders,
  });

  factory DailyBucket.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return DailyBucket(
      date: json['date'] as String,
      revenue: _toDouble(json['revenue']),
      cost: _toDouble(json['cost']),
      grossProfit: _toDouble(json['gross_profit']),
      orders: _toInt(json['orders']),
    );
  }
}

@immutable
class TotalsSummary {
  final double revenue;
  final double cost;
  final double grossProfit;
  final int orders;
  final double averageOrderValue;
  final double paid;
  final double due;

  const TotalsSummary({
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.orders,
    required this.averageOrderValue,
    required this.paid,
    required this.due,
  });

  factory TotalsSummary.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return TotalsSummary(
      revenue: _toDouble(json['revenue']),
      cost: _toDouble(json['cost']),
      grossProfit: _toDouble(json['gross_profit']),
      orders: _toInt(json['orders']),
      averageOrderValue: _toDouble(json['average_order_value']),
      paid: _toDouble(json['paid']),
      due: _toDouble(json['due']),
    );
  }
}

@immutable
class ReportResponse {
  final String periodType; // 'daily' or 'monthly'
  final Map<String, dynamic> period;
  final TotalsSummary totals;
  final List<TopProduct> topProducts;
  final List<DailyBucket> daily;
  final int salesCount;

  const ReportResponse({
    required this.periodType,
    required this.period,
    required this.totals,
    required this.topProducts,
    required this.daily,
    required this.salesCount,
  });

  factory ReportResponse.fromDailyJson(Map<String, dynamic> json) {
    return ReportResponse(
      periodType: (json['period']?['type'] as String?) ?? 'daily',
      period: Map<String, dynamic>.from(json['period'] ?? {}),
      totals: TotalsSummary.fromJson(Map<String, dynamic>.from(json['totals'] ?? {})),
      topProducts: (json['top_products'] as List<dynamic>? ?? [])
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: [],
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
    );
  }

  factory ReportResponse.fromMonthlyJson(Map<String, dynamic> json) {
    return ReportResponse(
      periodType: (json['period']?['type'] as String?) ?? 'monthly',
      period: Map<String, dynamic>.from(json['period'] ?? {}),
      totals: TotalsSummary.fromJson(Map<String, dynamic>.from(json['totals'] ?? {})),
      topProducts: (json['top_products'] as List<dynamic>? ?? [])
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List<dynamic>? ?? [])
          .map((e) => DailyBucket.fromJson(e as Map<String, dynamic>))
          .toList(),
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
    );
  }
}

// Inventory report models
@immutable
class InventoryProduct {
  final int productId;
  final String name;
  final int quantity;
  final double cost;
  final double stockValue;

  const InventoryProduct({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.cost,
    required this.stockValue,
  });

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return InventoryProduct(
      productId: _toInt(json['productId'] ?? json['product_id']),
      name: (json['name'] ?? '') as String,
      quantity: _toInt(json['quantity']),
      cost: _toDouble(json['cost']),
      stockValue: _toDouble(json['stockValue'] ?? json['stock_value']),
    );
  }
}

@immutable
class InventoryReport {
  final Map<String, dynamic> period;
  final Map<String, dynamic> totals;
  final List<InventoryProduct> products;
  final List<Map<String, dynamic>> lowStock;

  const InventoryReport({
    required this.period,
    required this.totals,
    required this.products,
    required this.lowStock,
  });

  factory InventoryReport.fromJson(Map<String, dynamic> json) {
    return InventoryReport(
      period: Map<String, dynamic>.from(json['period'] ?? {}),
      totals: Map<String, dynamic>.from(json['totals'] ?? {}),
      products: (json['products'] as List<dynamic>? ?? []).map((e) => InventoryProduct.fromJson(e as Map<String, dynamic>)).toList(),
      lowStock: (json['low_stock'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList(),
    );
  }
}

// Financial report models
@immutable
class FinancialReport {
  final Map<String, dynamic> period;
  final Map<String, dynamic> totals;
  final Map<String, dynamic> breakdown;

  const FinancialReport({required this.period, required this.totals, required this.breakdown});

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      period: Map<String, dynamic>.from(json['period'] ?? {}),
      totals: Map<String, dynamic>.from(json['totals'] ?? {}),
      breakdown: Map<String, dynamic>.from(json['breakdown'] ?? {}),
    );
  }
}

// Customers report models
@immutable
class CustomerSummary {
  final int customerId;
  final String name;
  final String? email;
  final double spend;

  const CustomerSummary({required this.customerId, required this.name, this.email, required this.spend});

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return CustomerSummary(
      customerId: _toInt(json['customerId'] ?? json['customer_id']),
      name: (json['name'] ?? '') as String,
      email: json['email'] as String?,
      spend: _toDouble(json['spend'] ?? json['total_spend']),
    );
  }
}

@immutable
class CustomersReport {
  final Map<String, dynamic> period;
  final Map<String, dynamic> totals;
  final List<CustomerSummary> topCustomers;
  final int salesCount;

  const CustomersReport({
    required this.period,
    required this.totals,
    required this.topCustomers,
    required this.salesCount,
  });

  factory CustomersReport.fromJson(Map<String, dynamic> json) {
    return CustomersReport(
      period: Map<String, dynamic>.from(json['period'] ?? {}),
      totals: Map<String, dynamic>.from(json['totals'] ?? {}),
      topCustomers: (json['top_customers'] as List<dynamic>? ?? []).map((e) => CustomerSummary.fromJson(e as Map<String, dynamic>)).toList(),
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
    );
  }
}