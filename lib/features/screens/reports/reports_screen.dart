// lib/features/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/screens/reports/data/sample_data.dart';
import 'package:sales_app/features/screens/reports/services/export_service.dart';
import 'package:sales_app/features/screens/reports/widgets/report_card_grid.dart';
import 'package:sales_app/features/screens/reports/widgets/report_chart_card.dart';
import 'package:sales_app/features/screens/reports/widgets/report_data_table.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
                // Wrap the PopupMenuButton in a Builder to get the correct context
                Builder(
                  builder: (context) => _buildExportButton(context),
                ),
                const SizedBox(width: AppSizes.padding),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabs: [
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
            children: [
              _buildReportSection(
                key: const PageStorageKey('sales_report_section'),
                cardData: SampleData.salesCardData,
                chartWidgets: [
                  ReportChartCard(title: 'Sales Trend', chartData: SampleData.salesTrendData, chartType: ChartType.line),
                  ReportChartCard(title: 'Top Products', chartData: SampleData.topProductsData, chartType: ChartType.bar),
                  ReportChartCard(title: 'Sales by Category', chartData: SampleData.salesByCategoryData, chartType: ChartType.pie),
                ],
                dataTable: ReportDataTable(title: 'Sales Data', headers: ['Date', 'Product', 'Revenue', 'Profit'], data: SampleData.salesData),
              ),
              _buildReportSection(
                key: const PageStorageKey('inventory_report_section'),
                cardData: SampleData.inventoryCardData,
                chartWidgets: [
                  ReportChartCard(title: 'Stock Level by Category', chartData: SampleData.stockByCategoryData, chartType: ChartType.bar),
                  ReportChartCard(title: 'Inventory Turnover Rate', chartData: SampleData.inventoryTurnoverData, chartType: ChartType.line),
                ],
                dataTable: ReportDataTable(title: 'Inventory Status', headers: ['Product', 'Stock', 'Status'], data: SampleData.inventoryData),
              ),
              _buildReportSection(
                key: const PageStorageKey('financial_report_section'),
                cardData: SampleData.financialCardData,
                chartWidgets: [
                  ReportChartCard(title: 'Revenue vs Expenses', chartData: SampleData.revenueVsExpensesData, chartType: ChartType.line),
                  ReportChartCard(title: 'Profit Margin Trend', chartData: SampleData.profitMarginData, chartType: ChartType.line),
                ],
                dataTable: ReportDataTable(title: 'Financial Overview', headers: ['Date', 'Revenue', 'Expenses', 'Profit'], data: SampleData.financialData),
              ),
              _buildReportSection(
                key: const PageStorageKey('customer_report_section'),
                cardData: SampleData.customerCardData,
                chartWidgets: [
                  ReportChartCard(title: 'New vs Returning Customers', chartData: SampleData.customerData, chartType: ChartType.pie),
                ],
                dataTable: ReportDataTable(title: 'Customer Segmentation', headers: ['Name', 'Email', 'Total Spent', 'Status'], data: SampleData.customerData),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection({
    required Key key,
    required List<Map<String, dynamic>> cardData,
    required List<Widget> chartWidgets,
    required Widget dataTable,
  }) {
    return ListView(
      key: key,
      primary: false,
      padding: const EdgeInsets.all(AppSizes.padding),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            int gridColumns;
            if (screenWidth >= 1100) {
              gridColumns = 4;
            } else if (screenWidth >= 650) {
              gridColumns = 2;
            } else {
              gridColumns = 1;
            }
            return ReportCardGrid(data: cardData, responsiveGrid: gridColumns);
          },
        ),
        ...chartWidgets.map((chart) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSizes.padding * 2),
            child: chart,
          );
        }).toList(),
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.padding * 2),
          child: dataTable,
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedPeriod,
      onSelected: (String value) {
        setState(() {
          _selectedPeriod = value;
        });
      },
      offset: const Offset(0, 50),
      child: Chip(
        avatar: const Icon(Icons.calendar_today, size: 18),
        label: Text(_selectedPeriod),
        backgroundColor: AppColors.kPrimary.withOpacity(0.1),
      ),
      itemBuilder: (BuildContext context) => [
        'Today',
        'This Week',
        'This Month',
        'Last 3 Months',
        'Custom Range',
      ].map((String value) {
        return PopupMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        List<Map<String, dynamic>> currentData;
        int tabIndex = DefaultTabController.of(context).index;
        switch (tabIndex) {
          case 0:
            currentData = SampleData.salesData;
            break;
          case 1:
            currentData = SampleData.inventoryData;
            break;
          case 2:
            currentData = SampleData.financialData;
            break;
          case 3:
            currentData = SampleData.customerData;
            break;
          default:
            currentData = SampleData.salesData;
        }

        if (value == 'csv') {
          await ExportService.exportToCsv(currentData);
        } else if (value == 'excel') {
          await ExportService.exportToExcel(currentData);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'excel',
          child: ListTile(
            leading: Icon(Icons.table_chart),
            title: Text('Export to Excel'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'csv',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text('Export to CSV'),
          ),
        ),
      ],
      icon: const Icon(Icons.download_rounded),
    );
  }
}
