import 'package:flutter/foundation.dart';

@immutable
class DashboardSummary {
  final double todaySalesTotal;
  final int todayOrdersCount;
  final double estimatedProfit; // revenue(today) - cost(buying price * quantity sold)
  final double todayExpensesTotal; // total expenses for today

  const DashboardSummary({
    required this.todaySalesTotal,
    required this.todayOrdersCount,
    required this.estimatedProfit,
    required this.todayExpensesTotal,
  });

  DashboardSummary copyWith({
    double? todaySalesTotal,
    int? todayOrdersCount,
    double? estimatedProfit,
    double? todayExpensesTotal,
  }) {
    return DashboardSummary(
      todaySalesTotal: todaySalesTotal ?? this.todaySalesTotal,
      todayOrdersCount: todayOrdersCount ?? this.todayOrdersCount,
      estimatedProfit: estimatedProfit ?? this.estimatedProfit,
      todayExpensesTotal: todayExpensesTotal ?? this.todayExpensesTotal,
    );
  }
}

enum ActivityType { sale, purchase, expense }

@immutable
class ActivityItem {
  final ActivityType type;
  final int id;
  final DateTime timestamp;
  final double amount;
  final String subtitle;

  const ActivityItem({
    required this.type,
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.subtitle,
  });
}

@immutable
class DashboardData {
  final DashboardSummary summary;
  final List<ActivityItem> recent;

  const DashboardData({
    required this.summary,
    required this.recent,
  });
}
