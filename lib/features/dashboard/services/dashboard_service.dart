import 'dart:async';

import 'package:sales_app/features/dashboard/data/dashboard_models.dart';
import 'package:sales_app/features/expenses/data/expense_model.dart';
import 'package:sales_app/features/expenses/services/expense_services.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';
import 'package:sales_app/features/purchases/services/purchase_service.dart';
import 'package:sales_app/features/sales/data/sales_model.dart';
import 'package:sales_app/features/sales/repository/sales_repository.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';

class DashboardService {
  final PurchaseService purchaseService;
  final SalesService salesService;
  final ProductService productService;
  final ExpenseService expenseService;

  DashboardService({
    required this.purchaseService,
    required this.salesService,
    required this.productService,
    required this.expenseService,
  });

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<DashboardData> fetch() async {
    // Build a quick repository for sales using the existing service
    final salesRepo = SalesRepository(service: salesService);

    // Fetch in parallel
    final results = await Future.wait([
      purchaseService.getAllPurchases(), // List<Purchase>
      salesRepo.getAllSales(),           // List<Sale>
      productService.getProducts(page: 1, limit: 10000), // List<Product>
      expenseService.getRawExpenses(),    // List<Map<String, dynamic>>
    ]);

    final purchases = results[0] as List<Purchase>;
    final sales = results[1] as List<Sale>;
    final products = results[2] as List<Product>;
    final expensesRaw = results[3] as List<Map<String, dynamic>>;
    
    // Convert raw expenses to Expense objects
    final expenses = expensesRaw.map((e) => Expense.fromJson(e)).toList();

    // Build product cost map (productId -> pricePerQuantity)
    final productCostMap = <int, double>{};
    for (final p in products) {
      productCostMap[p.id] = p.pricePerQuantity;
    }

    final now = DateTime.now();

    // Filter for today using proper date comparison
    final todaysSales = sales.where((s) => _isSameDay(s.soldAt, now)).toList();
    final todaysPurchases = purchases.where((p) => _isSameDay(p.date, now)).toList();
    final todaysExpenses = expenses.where((e) => _isSameDay(e.dateIncurred, now)).toList();

    final todaySalesTotal = todaysSales.fold<double>(0.0, (sum, s) => sum + (s.totalAmount ?? 0.0));
    final todayOrdersCount = todaysSales.length;
    final todayExpensesTotal = todaysExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    // Fetch sale details with items for today's sales to calculate cost
    double todayCost = 0.0;
    for (final sale in todaysSales) {
      final saleDetails = await salesService.getSaleById(sale.id);
      if (saleDetails != null) {
        for (final item in saleDetails.items) {
          final costPerUnit = productCostMap[item.productId] ?? 0.0;
          todayCost += costPerUnit * item.quantitySold;
        }
      }
    }

    // Profit = Revenue - Cost (buying price * quantity)
    final estimatedProfit = todaySalesTotal - todayCost;

    // Build recent activity (mix last 10 of all three)
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

    final recentExpenses = expenses
        .map<ActivityItem>((e) => ActivityItem(
              type: ActivityType.expense,
              id: e.id,
              timestamp: e.dateIncurred,
              amount: e.amount,
              subtitle: e.description.isNotEmpty ? e.description : 'Expense #${e.id}',
            ))
        .toList();

    final merged = [...recentSales, ...recentPurchases, ...recentExpenses]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final recent = merged.take(10).toList();

    return DashboardData(
      summary: DashboardSummary(
        todaySalesTotal: todaySalesTotal,
        todayOrdersCount: todayOrdersCount,
        estimatedProfit: estimatedProfit,
        todayExpensesTotal: todayExpensesTotal,
      ),
      recent: recent,
    );
  }
}
