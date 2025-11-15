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
  String _selectedPeriod = 'Today';
  late final TabController _tabController;

  // Custom range (inclusive)
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now().toUtc();
    // Load monthly once; we filter client-side for Today/This Week/Custom
    context.read<ReportsBloc>().add(LoadMonthlyReport(now.year, now.month));
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    // With custom/client-side filter, just rebuild UI
    if (_customRange != null) {
      setState(() {});
      return;
    }

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

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 3, 1, 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final initial = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );

    final result = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initial,
      saveText: 'Apply',
      helpText: 'Select Custom Range',
      builder: (ctx, child) {
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.kPrimary,
              onPrimary: AppColors.kTextOnPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _customRange = DateTimeRange(
          start: DateTime(result.start.year, result.start.month, result.start.day),
          end: DateTime(result.end.year, result.end.month, result.end.day),
        );
        _selectedPeriod = '${_fmtYMD(_customRange!.start)} – ${_fmtYMD(_customRange!.end)}';
      });
    }
  }

  void _onPeriodSelected(String period) async {
    if (period == 'Custom Range') {
      await _pickCustomRange();
      // Immediate client-side update (no backend call)
      setState(() {});
      return;
    }

    setState(() {
      _customRange = null;
      _selectedPeriod = period;
    });

    // Only refresh for ranges that truly change the source dataset
    final bloc = context.read<ReportsBloc>();
    final now = DateTime.now().toUtc();
    if (period == 'This Month') {
      bloc.add(LoadMonthlyReport(now.year, now.month));
    } else if (period == 'Last 3 Months') {
      final threeMonthsAgo = DateTime.utc(now.year, now.month - 2, 1);
      bloc.add(LoadMonthlyReport(threeMonthsAgo.year, threeMonthsAgo.month));
    }
  }

  // Build active range based on selection
  DateTimeRange? _activeRange() {
    if (_customRange != null) return _customRange;
    final now = DateTime.now();
    if (_selectedPeriod == 'Today') {
      final d = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: d, end: d);
    }
    if (_selectedPeriod == 'This Week') {
      final d = DateTime(now.year, now.month, now.day);
      final start = d.subtract(Duration(days: d.weekday - 1)); // Monday
      final end = start.add(const Duration(days: 6));
      return DateTimeRange(start: start, end: end);
    }
    if (_selectedPeriod == 'This Month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return DateTimeRange(start: start, end: end);
    }
    return null;
  }

  // Normalize date string to yyyy-MM-dd (drop time/TZ parts safely)
  String _dateOnlyStr(String s) {
    final t = s.trim();
    if (t.length >= 10 && (t.contains('T') || t.contains(' '))) {
      return t.substring(0, 10);
    }
    if (t.contains('/')) {
      final p = t.split('/');
      if (p.length == 3) {
        final d = p[0].padLeft(2, '0');
        final m = p[1].padLeft(2, '0');
        final y = p[2].padLeft(4, '0');
        return '$y-$m-$d';
      }
    }
    if (t.contains('-') && t.length >= 10) {
      return t.substring(0, 10);
    }
    return t;
  }

  DateTime? _parseDateSafe(String s) {
    final iso = _dateOnlyStr(s);
    try {
      final parts = iso.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  List<dynamic> _filterDailyByActiveRange(List<dynamic> daily) {
    final range = _activeRange();
    if (range == null) return daily;
    return daily.where((d) {
      final dt = _parseDateSafe(d.date);
      if (dt == null) return false;
      return !dt.isBefore(range.start) && !dt.isAfter(range.end);
    }).toList();
  }

  // EXPORT MENU ----------------------------------------------------------------
  Widget _buildExportButton(BuildContext context, ReportsState state) {
    final enabled = state is SalesReportLoaded ||
        state is InventoryReportLoaded ||
        state is FinancialReportLoaded ||
        state is CustomersReportLoaded;

    return PopupMenuButton<String>(
      onSelected: enabled ? (value) => _onExportSelected(context, value, state) : null,
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem<String>(
          value: 'excel',
          child: ListTile(leading: Icon(Icons.table_chart), title: Text('Export to Excel (.xlsx)')),
        ),
        PopupMenuItem<String>(
          value: 'csv',
          child: ListTile(leading: Icon(Icons.download), title: Text('Export to CSV (.csv)')),
        ),
        PopupMenuItem<String>(
          value: 'pdf',
          child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Export to PDF (.pdf)')),
        ),
      ],
      icon: const Icon(Icons.download_rounded),
      enabled: enabled,
    );
  }

  Future<void> _onExportSelected(BuildContext context, String value, ReportsState state) async {
    // SALES -------------------------------------------------------------------
    if (state is SalesReportLoaded) {
      final report = state.report;
      final usingDaily = report.daily.isNotEmpty;

      // Use exactly what UI shows
      final filteredDaily = _filterDailyByActiveRange(report.daily);

      if (value == 'csv') {
        final data = usingDaily
            ? filteredDaily
                .map((d) => {
                      'date': _dateOnlyStr(d.date),
                      'revenue': d.revenue,
                      'cost': d.cost,
                      'profit': d.grossProfit,
                      'orders': d.orders
                    })
                .toList()
            : report.topProducts
                .map((p) => {'product_id': p.productId, 'revenue': p.revenue, 'quantity': p.quantity})
                .toList();
        await ExportService.exportToCsv(data, fileName: 'sales_${_fileSuffix()}.csv');
        return;
      }

      if (value == 'excel') {
        final data = usingDaily
            ? filteredDaily
                .map((d) => {
                      'Date': _dateOnlyStr(d.date),
                      'Revenue': d.revenue,
                      'Cost': d.cost,
                      'Profit': d.grossProfit,
                      'Orders': d.orders
                    })
                .toList()
            : report.topProducts
                .map((p) => {'ProductId': p.productId, 'Revenue': p.revenue, 'Quantity': p.quantity})
                .toList();
        await ExportService.exportToExcel(data, fileName: 'sales_${_fileSuffix()}.xlsx', sheetName: 'Sales');
        return;
      }

      if (value == 'pdf') {
        final range = _activeRange();
        final titlePrefix = _selectedPeriod == 'Today'
            ? 'Daily'
            : (_selectedPeriod == 'This Week'
                ? 'Weekly'
                : (_selectedPeriod == 'This Month' ? 'Monthly' : 'Sales'));
        final title = range == null
            ? 'Sales Report'
            : '$titlePrefix Sales Report - ${_fmtYMD(range.start)}${range.end != range.start ? ' to ${_fmtYMD(range.end)}' : ''}';

        if (usingDaily) {
          final headers = ['Date', 'Revenue', 'Cost', 'Profit', 'Orders'];
          // IMPORTANT: pass numbers so the export can compute totals and format nicely
          final numericRows = filteredDaily
              .map((d) => [_dateOnlyStr(d.date), d.revenue, d.cost, d.grossProfit, d.orders])
              .toList();
          await ExportService.exportSalesTableReportPdf(
            title: title,
            subtitle: _selectedPeriod,
            headers: headers,
            rows: numericRows,
            fileName: 'sales_${_fileSuffix()}.pdf',
            currencyFmt: (n) => CurrencyFmt.format(context, n),
          );
        } else {
          final headers = ['Product', 'Revenue', 'Qty'];
          final rows = report.topProducts.map((p) => [p.productId.toString(), p.revenue, p.quantity]).toList();
          await ExportService.exportSalesTableReportPdf(
            title: 'Top Products - ${_selectedPeriod}',
            headers: headers,
            rows: rows,
            fileName: 'sales_${_fileSuffix()}.pdf',
            currencyFmt: (n) => CurrencyFmt.format(context, n),
          );
        }
        return;
      }
    }

    // INVENTORY ---------------------------------------------------------------
    if (state is InventoryReportLoaded) {
      final inv = state.report;

      if (value == 'csv') {
        final data = inv.products
            .map((p) => {
                  'product_id': p.productId,
                  'name': p.name,
                  'quantity': p.quantity,
                  'cost': p.cost,
                  'stock_value': p.stockValue
                })
            .toList();
        await ExportService.exportToCsv(data, fileName: 'inventory_${_fileSuffix()}.csv');
        return;
      }

      if (value == 'excel') {
        final data = inv.products
            .map((p) => {
                  'ProductId': p.productId,
                  'Name': p.name,
                  'Quantity': p.quantity,
                  'Cost': p.cost,
                  'StockValue': p.stockValue
                })
            .toList();
        await ExportService.exportToExcel(data, fileName: 'inventory_${_fileSuffix()}.xlsx', sheetName: 'Inventory');
        return;
      }

      if (value == 'pdf') {
        final headers = ['Product', 'Qty', 'Cost', 'Stock Value'];
        final rows = inv.products.map((p) => [p.name, p.quantity, p.cost, p.stockValue]).toList();
        await ExportService.exportSalesTableReportPdf(
          title: 'Inventory Report - ${_selectedPeriod}',
          headers: headers,
          rows: rows,
          fileName: 'inventory_${_fileSuffix()}.pdf',
          currencyFmt: (n) => CurrencyFmt.format(context, n),
        );
        return;
      }
    }

    // FINANCIAL ---------------------------------------------------------------
    if (state is FinancialReportLoaded) {
      final fin = state.report;
      if (value == 'csv') {
        final totals = fin.totals.entries.map((e) => {'metric': e.key, 'value': e.value}).toList();
        await ExportService.exportToCsv(totals, fileName: 'financial_${_fileSuffix()}.csv');
        return;
      }
      if (value == 'excel') {
        final totals = fin.totals.entries.map((e) => {'Metric': e.key, 'Value': e.value}).toList();
        await ExportService.exportToExcel(totals, fileName: 'financial_${_fileSuffix()}.xlsx', sheetName: 'Financial');
        return;
      }
      if (value == 'pdf') {
        final headers = ['Metric', 'Value'];
        final rows = fin.totals.entries.map((e) => [e.key, e.value is num ? (e.value as num) : e.value.toString()]).toList();
        await ExportService.exportSalesTableReportPdf(
          title: 'Financial Report - ${_selectedPeriod}',
          headers: headers,
          rows: rows,
          fileName: 'financial_${_fileSuffix()}.pdf',
          currencyFmt: (n) => CurrencyFmt.format(context, n),
        );
        return;
      }
    }

    // CUSTOMERS ---------------------------------------------------------------
    if (state is CustomersReportLoaded) {
      final cr = state.report;
      if (value == 'csv') {
        final data = cr.topCustomers
            .map((c) => {'customer_id': c.customerId, 'name': c.name, 'email': c.email ?? '', 'spend': c.spend})
            .toList();
        await ExportService.exportToCsv(data, fileName: 'customers_${_fileSuffix()}.csv');
        return;
      }
      if (value == 'excel') {
        final data = cr.topCustomers
            .map((c) => {'CustomerId': c.customerId, 'Name': c.name, 'Email': c.email ?? '', 'Spend': c.spend})
            .toList();
        await ExportService.exportToExcel(data, fileName: 'customers_${_fileSuffix()}.xlsx', sheetName: 'Customers');
        return;
      }
      if (value == 'pdf') {
        final headers = ['Customer', 'Email', 'Spend'];
        final rows = cr.topCustomers.map((c) => [c.name, c.email ?? '', c.spend]).toList();
        await ExportService.exportSalesTableReportPdf(
          title: 'Customers Report - ${_selectedPeriod}',
          headers: headers,
          rows: rows,
          fileName: 'customers_${_fileSuffix()}.pdf',
          currencyFmt: (n) => CurrencyFmt.format(context, n),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
  }

  String _fileSuffix() {
    final d = DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final period = _selectedPeriod.replaceAll(' ', '_').replaceAll('/', '-');
    return '${period.toLowerCase()}_${y}${m}${da}_$hh$mm';
  }

  // VIEWS ---------------------------------------------------------------------
  Widget _buildSalesView(ReportResponse report) {
    final List<dynamic> daily = _filterDailyByActiveRange(report.daily);

    num sum(num Function(dynamic d) pick) => daily.fold<num>(0, (s, e) => s + (pick(e) as num));
    final revenueSum = daily.isNotEmpty ? sum((d) => d.revenue) : (report.totals.revenue);
    final profitSum = daily.isNotEmpty ? sum((d) => d.grossProfit) : (report.totals.grossProfit);
    final ordersSum = daily.isNotEmpty ? sum((d) => d.orders) : (report.totals.orders);
    final avgOrder = (ordersSum > 0) ? (revenueSum / ordersSum) : 0;

    final revenueTrend = daily.map((d) => {'label': _dateOnlyStr(d.date), 'value': d.revenue}).toList();
    final topProducts = report.topProducts.map((p) => {'label': p.productId.toString(), 'value': p.revenue}).toList();

    final range = _activeRange();
    final rangeSuffix = range == null
        ? ''
        : ' (${_fmtYMD(range.start)}${range.end != range.start ? ' – ${_fmtYMD(range.end)}' : ''})';

    final dataTable = ReportDataTable(
      title: 'Daily Breakdown$rangeSuffix',
      headers: const ['Date', 'Revenue', 'Cost', 'Profit', 'Orders'],
      data: daily
          .map((d) => {
                'Date': _dateOnlyStr(d.date),
                'Revenue': d.revenue,
                'Cost': d.cost,
                'Profit': d.grossProfit,
                'Orders': d.orders
              })
          .toList(),
    );

    final cards = [
      {'title': 'Revenue', 'value': CurrencyFmt.format(context, revenueSum), 'color': AppColors.kPrimary},
      {'title': 'Gross Profit', 'value': CurrencyFmt.format(context, profitSum), 'color': Colors.green},
      {'title': 'Orders', 'value': ordersSum.toString(), 'color': Colors.blueGrey},
      {'title': 'Avg Order', 'value': CurrencyFmt.format(context, avgOrder), 'color': Colors.orange},
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
        ReportChartCard(title: 'Revenue Trend$rangeSuffix', chartData: revenueTrend, chartType: ChartType.line),
        const SizedBox(height: AppSizes.padding * 2),
        ReportChartCard(title: 'Top Products', chartData: topProducts, chartType: ChartType.bar),
        const SizedBox(height: AppSizes.padding * 2),
        dataTable,
      ],
    );
  }

  Widget _buildInventoryView(InventoryReport report) {
    final cards = [
      {'title': 'Stock Value', 'value': CurrencyFmt.format(context, (report.totals['total_stock_value'] ?? 0) as num), 'color': AppColors.kPrimary},
      {'title': 'Total Items', 'value': '${report.totals['total_items'] ?? 0}', 'color': Colors.blueGrey},
      {'title': 'Low Stock', 'value': '${report.totals['low_stock_count'] ?? 0}', 'color': Colors.orange},
    ];

    final productRows =
        report.products.map((p) => {'Product': p.name, 'Qty': p.quantity, 'Cost': p.cost, 'StockValue': p.stockValue}).toList();

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
              {'title': 'Revenue', 'value': CurrencyFmt.format(context, (report.totals['revenue'] ?? 0) as num), 'color': AppColors.kPrimary},
              {'title': 'Expenses', 'value': CurrencyFmt.format(context, (report.totals['expenses'] ?? 0) as num), 'color': Colors.red},
              {'title': 'Net Profit', 'value': CurrencyFmt.format(context, (report.totals['net_profit'] ?? 0) as num), 'color': Colors.green},
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
      {'title': 'Customers', 'value': '${report.totals['customers_count'] ?? 0}', 'color': AppColors.kPrimary},
      {'title': 'New', 'value': '${report.totals['new_customers'] ?? 0}', 'color': Colors.green},
      {'title': 'Returning', 'value': '${report.totals['returning_customers'] ?? 0}', 'color': Colors.orange},
    ];

    final rows = report.topCustomers.map((c) => {'Name': c.name, 'Email': c.email ?? '', 'Spend': c.spend}).toList();

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load data. Please try again.'),
              backgroundColor: AppColors.kError,
            ),
          );
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

  // Utils ---------------------------------------------------------------------
  String _fmtYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}