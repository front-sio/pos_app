import 'dart:async';

import 'package:sales_app/features/dashboard/data/dashboard_models.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';
import 'package:sales_app/features/purchases/services/purchase_service.dart';
import 'package:sales_app/features/sales/data/sales_model.dart';
import 'package:sales_app/features/sales/repository/sales_repository.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';

class DashboardService {
  final PurchaseService purchaseService;
  final SalesService salesService;

  DashboardService({
    required this.purchaseService,
    required this.salesService,
  });

  Future<DashboardData> fetch() async {
    // Build a quick repository for sales using the existing service
    final salesRepo = SalesRepository(service: salesService);

    // Fetch in parallel
    final results = await Future.wait([
      purchaseService.getAllPurchases(), // List<Purchase>
      salesRepo.getAllSales(),           // List<Sale>
    ]);

    final purchases = results[0] as List<Purchase>;
    final sales = results[1] as List<Sale>;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Filter for today
    final todaysSales = sales.where((s) => s.soldAt.isAfter(startOfToday)).toList();
    final todaysPurchases = purchases.where((p) => p.date.isAfter(startOfToday)).toList();

    final todaySalesTotal = todaysSales.fold<double>(0.0, (sum, s) => sum + (s.totalAmount ?? 0.0));
    final todayOrdersCount = todaysSales.length;
    final todayPurchasesTotal = todaysPurchases.fold<double>(0.0, (sum, p) => sum + p.total);
    final estimatedProfit = todaySalesTotal - todayPurchasesTotal;

    // Build recent activity (mix last 10 of both)
    final recentSales = sales
        .map<ActivityItem>((s) => ActivityItem(
              type: ActivityType.sale,
              id: s.id,
              timestamp: s.soldAt,
              amount: (s.totalAmount ?? 0.0),
              subtitle: 'Sale #${s.id}',
            ))
        .toList();

    final recentPurchases = purchases
        .map<ActivityItem>((p) => ActivityItem(
              type: ActivityType.purchase,
              id: p.id,
              timestamp: p.date,
              amount: p.total,
              subtitle: 'Purchase #${p.id}',
            ))
        .toList();

    final merged = [...recentSales, ...recentPurchases]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final recent = merged.take(10).toList();

    return DashboardData(
      summary: DashboardSummary(
        todaySalesTotal: todaySalesTotal,
        todayOrdersCount: todayOrdersCount,
        estimatedProfit: estimatedProfit,
      ),
      recent: recent,
    );
  }
}