import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/reports/bloc/reports_bloc.dart';
import 'package:sales_app/features/reports/bloc/reports_event.dart';
import 'package:sales_app/features/reports/bloc/reports_state.dart';
import 'package:sales_app/features/reports/models/report_model.dart';
import 'package:sales_app/features/reports/services/export_service.dart';
import 'package:sales_app/features/reports/widgets/report_card_grid.dart';
import 'package:sales_app/features/reports/widgets/report_chart_card.dart';
import 'package:sales_app/features/reports/widgets/report_data_table.dart';
import 'package:sales_app/utils/currency.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'This Month';
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now().toUtc();
    context.read<ReportsBloc>().add(LoadMonthlyReport(now.year, now.month));
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final idx = _tabController.index;
    final now = DateTime.now().toUtc();
    final bloc = context.read<ReportsBloc>();
    if (idx == 0) {
      bloc.add(LoadMonthlyReport(now.year, now.month));
    } else if (idx == 1) {
      bloc.add(LoadInventoryReport(threshold: 10));
    } else if (idx == 2) {
      bloc.add(LoadFinancialReport(now.year, now.month));
    } else if (idx == 3) {
      bloc.add(LoadCustomersReport(now.year, now.month));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onPeriodSelected(String period) {
    setState(() => _selectedPeriod = period);
    final bloc = context.read<ReportsBloc>();
    final now = DateTime.now().toUtc();
    if (period == 'Today') {
      bloc.add(LoadDailyReport(DateTime.utc(now.year, now.month, now.day)));
    } else if (period == 'This Week') {
      // For now reuse monthly; replace with weekly endpoint if available
      bloc.add(LoadMonthlyReport(now.year, now.month));
    } else if (period == 'This Month') {
      bloc.add(LoadMonthlyReport(now.year, now.month));
    } else if (period == 'Last 3 Months') {
      final threeMonthsAgo = DateTime.utc(now.year, now.month - 2, 1);
      bloc.add(LoadMonthlyReport(threeMonthsAgo.year, threeMonthsAgo.month));
    } else {
      bloc.add(LoadMonthlyReport(now.year, now.month));
    }
  }

  Widget _buildExportButton(BuildContext context, ReportsState state) {
    final enabled = state is SalesReportLoaded ||
        state is InventoryReportLoaded ||
        state is FinancialReportLoaded ||
        state is CustomersReportLoaded;
    return PopupMenuButton<String>(
      onSelected: enabled
          ? (value) async {
              // Export raw numeric data (no currency symbols) for CSV/Excel
              if (state is SalesReportLoaded) {
                final report = state.report;
                final data = report.daily.isNotEmpty
                    ? report.daily
                        .map((d) => {
                              'date': d.date,
                              'revenue': d.revenue,
                              'cost': d.cost,
                              'profit': d.grossProfit,
                              'orders': d.orders
                            })
                        .toList()
                    : report.topProducts
                        .map((p) => {
                              'product_id': p.productId,
                              'revenue': p.revenue,
                              'quantity': p.quantity
                            })
                        .toList();
                if (value == 'csv') {
                  await ExportService.exportToCsv(data);
                } else {
                  await ExportService.exportToExcel(data);
                }
                return;
              }
              if (state is InventoryReportLoaded) {
                final inv = state.report;
                final data = inv.products
                    .map((p) => {
                          'productId': p.productId,
                          'name': p.name,
                          'quantity': p.quantity,
                          'cost': p.cost,
                          'stockValue': p.stockValue
                        })
                    .toList();
                if (value == 'csv') {
                  await ExportService.exportToCsv(data);
                } else {
                  await ExportService.exportToExcel(data);
                }
                return;
              }
              if (state is FinancialReportLoaded) {
                final fin = state.report;
                final totals = fin.totals.entries.map((e) => {'key': e.key, 'value': e.value}).toList();
                if (value == 'csv') {
                  await ExportService.exportToCsv(totals);
                } else {
                  await ExportService.exportToExcel(totals);
                }
                return;
              }
              if (state is CustomersReportLoaded) {
                final cr = state.report;
                final data = cr.topCustomers
                    .map((c) => {
                          'customerId': c.customerId,
                          'name': c.name,
                          'email': c.email ?? '',
                          'spend': c.spend
                        })
                    .toList();
                if (value == 'csv') {
                  await ExportService.exportToCsv(data);
                } else {
                  await ExportService.exportToExcel(data);
                }
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
            }
          : null,
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem<String>(
          value: 'excel',
          child: ListTile(leading: Icon(Icons.table_chart), title: Text('Export to Excel')),
        ),
        PopupMenuItem<String>(
          value: 'csv',
          child: ListTile(leading: Icon(Icons.download), title: Text('Export to CSV')),
        ),
      ],
      icon: const Icon(Icons.download_rounded),
      enabled: enabled,
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedPeriod,
      onSelected: _onPeriodSelected,
      offset: const Offset(0, 50),
      child: Chip(
        avatar: const Icon(Icons.calendar_today, size: 18),
        label: Text(_selectedPeriod),
        backgroundColor: AppColors.kPrimary.withOpacity(0.08),
      ),
      itemBuilder: (BuildContext context) =>
          ['Today', 'This Week', 'This Month', 'Last 3 Months', 'Custom Range']
              .map((String value) => PopupMenuItem<String>(value: value, child: Text(value)))
              .toList(),
    );
  }

  Widget _buildSalesView(ReportResponse report) {
    // Chart data (keep numeric values)
    final revenueTrend = report.daily.map((d) => {'label': d.date, 'value': d.revenue}).toList();
    final topProducts = report.topProducts
        .map((p) => {'label': p.productId.toString(), 'value': p.revenue})
        .toList();

    // Table data (numbers left raw; ReportDataTable will format currency-friendly keys)
    final dataTable = ReportDataTable(
      title: 'Daily Breakdown',
      headers: const ['Date', 'Revenue', 'Cost', 'Profit', 'Orders'],
      data: report.daily
          .map((d) => {
                'Date': d.date,
                'Revenue': d.revenue,
                'Cost': d.cost,
                'Profit': d.grossProfit,
                'Orders': d.orders
              })
          .toList(),
    );

    // KPI cards (format with CurrencyFmt)
    final cards = [
      {
        'title': 'Revenue',
        'value': CurrencyFmt.format(context, report.totals.revenue),
        'color': AppColors.kPrimary
      },
      {
        'title': 'Gross Profit',
        'value': CurrencyFmt.format(context, report.totals.grossProfit),
        'color': Colors.green
      },
      {
        'title': 'Orders',
        'value': report.totals.orders.toString(),
        'color': Colors.blueGrey
      },
      {
        'title': 'Avg Order',
        'value': CurrencyFmt.format(context, report.totals.averageOrderValue),
        'color': Colors.orange
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSizes.padding),
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cols = width >= 1100 ? 4 : (width >= 650 ? 2 : 1);
          return ReportCardGrid(data: cards, responsiveGrid: cols);
        }),
        const SizedBox(height: AppSizes.padding * 2),
        ReportChartCard(title: 'Revenue Trend', chartData: revenueTrend, chartType: ChartType.line),
        const SizedBox(height: AppSizes.padding * 2),
        ReportChartCard(title: 'Top Products', chartData: topProducts, chartType: ChartType.bar),
        const SizedBox(height: AppSizes.padding * 2),
        dataTable,
      ],
    );
  }

  Widget _buildInventoryView(InventoryReport report) {
    final cards = [
      {
        'title': 'Stock Value',
        'value': CurrencyFmt.format(context, (report.totals['total_stock_value'] ?? 0) as num),
        'color': AppColors.kPrimary
      },
      {
        'title': 'Total Items',
        'value': '${report.totals['total_items'] ?? 0}',
        'color': Colors.blueGrey
      },
      {
        'title': 'Low Stock',
        'value': '${report.totals['low_stock_count'] ?? 0}',
        'color': Colors.orange
      },
    ];

    final productRows = report.products
        .map((p) => {
              'Product': p.name,
              'Qty': p.quantity,
              'Cost': p.cost, // formatted in table
              'StockValue': p.stockValue, // formatted in table
            })
        .toList();

    final dataTable = ReportDataTable(
      title: 'Products',
      headers: const ['Product', 'Qty', 'Cost', 'StockValue'],
      data: productRows,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSizes.padding),
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cols = width >= 1100 ? 4 : (width >= 650 ? 2 : 1);
          return ReportCardGrid(data: cards, responsiveGrid: cols);
        }),
        const SizedBox(height: AppSizes.padding * 2),
        dataTable,
      ],
    );
  }

  Widget _buildFinancialView(FinancialReport report) {
    final totals = report.totals.entries.map((e) => {'key': e.key, 'value': e.value}).toList();

    final dataTable = ReportDataTable(
      title: 'Financial Summary',
      headers: const ['Metric', 'Value'],
      data: totals.map((r) => {'Metric': r['key'], 'Value': r['value']}).toList(),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSizes.padding),
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cols = width >= 1100 ? 4 : (width >= 650 ? 2 : 1);
          return ReportCardGrid(
            data: [
              {
                'title': 'Revenue',
                'value': CurrencyFmt.format(context, (report.totals['revenue'] ?? 0) as num),
                'color': AppColors.kPrimary
              },
              {
                'title': 'Expenses',
                'value': CurrencyFmt.format(context, (report.totals['expenses'] ?? 0) as num),
                'color': Colors.red
              },
              {
                'title': 'Net Profit',
                'value': CurrencyFmt.format(context, (report.totals['net_profit'] ?? 0) as num),
                'color': Colors.green
              },
            ],
            responsiveGrid: cols,
          );
        }),
        const SizedBox(height: AppSizes.padding * 2),
        dataTable,
      ],
    );
  }

  Widget _buildCustomersView(CustomersReport report) {
    final cards = [
      {
        'title': 'Customers',
        'value': '${report.totals['customers_count'] ?? 0}',
        'color': AppColors.kPrimary
      },
      {'title': 'New', 'value': '${report.totals['new_customers'] ?? 0}', 'color': Colors.green},
      {
        'title': 'Returning',
        'value': '${report.totals['returning_customers'] ?? 0}',
        'color': Colors.orange
      },
    ];

    final rows = report.topCustomers
        .map((c) => {
              'Name': c.name,
              'Email': c.email ?? '',
              'Spend': c.spend, // formatted in table
            })
        .toList();

    final dataTable = ReportDataTable(
      title: 'Top Customers',
      headers: const ['Name', 'Email', 'Spend'],
      data: rows,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSizes.padding),
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cols = width >= 1100 ? 4 : (width >= 650 ? 2 : 1);
          return ReportCardGrid(data: cards, responsiveGrid: cols);
        }),
        const SizedBox(height: AppSizes.padding * 2),
        dataTable,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state is ReportsError) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.kError));
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: const Text('Reports & Analytics'),
                actions: [
                  _buildPeriodSelector(),
                  const SizedBox(width: AppSizes.padding),
                  Builder(builder: (ctx) => _buildExportButton(ctx, state)),
                  const SizedBox(width: AppSizes.padding),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Sales'),
                    Tab(text: 'Inventory'),
                    Tab(text: 'Financial'),
                    Tab(text: 'Customers'),
                  ],
                  indicatorColor: AppColors.kPrimary,
                  labelColor: AppColors.kPrimary,
                  unselectedLabelColor: AppColors.kTextSecondary,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                if (state is SalesReportLoaded)
                  _buildSalesView(state.report)
                else if (state is ReportsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is ReportsError)
                  Center(child: Text(state.message))
                else
                  const Center(child: Text('No sales report loaded')),
                if (state is InventoryReportLoaded)
                  _buildInventoryView(state.report)
                else if (state is ReportsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is ReportsError)
                  Center(child: Text(state.message))
                else
                  const Center(child: Text('No inventory report loaded')),
                if (state is FinancialReportLoaded)
                  _buildFinancialView(state.report)
                else if (state is ReportsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is ReportsError)
                  Center(child: Text(state.message))
                else
                  const Center(child: Text('No financial report loaded')),
                if (state is CustomersReportLoaded)
                  _buildCustomersView(state.report)
                else if (state is ReportsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is ReportsError)
                  Center(child: Text(state.message))
                else
                  const Center(child: Text('No customers report loaded')),
              ],
            ),
          ),
        );
      },
    );
  }
}