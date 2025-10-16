import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/purchases/bloc/purchase_bloc.dart';
import 'package:sales_app/features/purchases/bloc/purchase_event.dart';
import 'package:sales_app/features/purchases/bloc/purchase_state.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';
import 'package:sales_app/widgets/animated_card.dart';
import 'package:sales_app/widgets/responsive_grid.dart';

class PurchasesScreen extends StatefulWidget {
  final VoidCallback? onAddNewPurchase;
  const PurchasesScreen({super.key, this.onAddNewPurchase});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDateRange = 'This Month';

  List<Purchase> _lastKnownPurchases = const <Purchase>[];

  @override
  void initState() {
    super.initState();
    context.read<PurchaseBloc>().add(const LoadPurchases());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: BlocConsumer<PurchaseBloc, PurchaseState>(
                  listenWhen: (prev, curr) => curr is PurchaseError || curr is PurchaseOperationSuccess,
                  listener: (context, state) {
                    if (state is PurchaseOperationSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: AppColors.kSuccess),
                      );
                    }
                    if (state is PurchaseError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: AppColors.kError),
                      );
                    }
                  },
                  buildWhen: (prev, curr) => curr is PurchaseLoading || curr is PurchaseLoaded,
                  builder: (context, state) {
                    if (state is PurchaseLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    List<Purchase> purchases = _lastKnownPurchases;
                    if (state is PurchaseLoaded) {
                      purchases = state.purchases;
                      _lastKnownPurchases = purchases;
                    }

                    // Newest first
                    final baseSorted = [...purchases]..sort((a, b) {
                      final byDate = b.date.compareTo(a.date);
                      if (byDate != 0) return byDate;
                      return b.id.compareTo(a.id);
                    });

                    final filtered = _applySearch(baseSorted);

                    // KPI: total spend, by status
                    final totalSpend = filtered.fold<double>(0.0, (s, p) => s + p.total);
                    final paidSpend = filtered.where((p) => p.status == 'paid').fold<double>(0.0, (s, p) => s + p.total);
                    final due = filtered.fold<double>(0.0, (s, p) => s + p.dueAmount);

                    return Column(
                      children: [
                        _buildStats(totalSpend, paidSpend, due, filtered.length),
                        const SizedBox(height: AppSizes.padding),
                        _buildFilters(),
                        const SizedBox(height: AppSizes.padding),
                        _buildList(isDesktop, filtered),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddNewPurchase,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Purchase'),
        backgroundColor: AppColors.kPrimary,
      ),
    );
  }

  List<Purchase> _applySearch(List<Purchase> purchases) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return purchases;
    return purchases.where((p) {
      final supplierMatch = (p.supplierName ?? 'supplier #${p.supplierId ?? ''}').toLowerCase().contains(q);
      final idMatch = p.id.toString().contains(q);
      final itemNames = p.items.map((i) => (i.productName ?? '')).join(' ').toLowerCase();
      return supplierMatch || idMatch || itemNames.contains(q);
    }).toList();
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 2,
      forceElevated: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purchases', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('Track multi-item supplier purchases and payments',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.kTextSecondary)),
        ],
      ),
      actions: [
        _buildDateRangePicker(),
        const SizedBox(width: AppSizes.padding),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<PurchaseBloc>().add(const LoadPurchases()),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<String>(
        initialValue: _selectedDateRange,
        onSelected: (value) => setState(() => _selectedDateRange = value),
        child: Chip(
          avatar: const Icon(Icons.calendar_today, size: 18),
          label: Text(_selectedDateRange),
          backgroundColor: AppColors.kPrimary.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        itemBuilder: (context) => [
          'Today',
          'This Week',
          'This Month',
          'Last 3 Months',
          'Custom Range',
        ].map((v) => PopupMenuItem(value: v, child: Text(v))).toList(),
      ),
    );
  }

  Widget _buildStats(double totalSpend, double paidSpend, double due, int totalOrders) {
    return ResponsiveGrid(
      spacing: AppSizes.padding,
      runSpacing: AppSizes.padding,
      children: [
        _statCard('Total Spend', '\$${totalSpend.toStringAsFixed(2)}', Icons.payments, AppColors.kPrimary, '$totalOrders orders'),
        _statCard('Paid', '\$${paidSpend.toStringAsFixed(2)}', Icons.check_circle, AppColors.kSuccess, 'Settled'),
        _statCard('Outstanding', '\$${due.toStringAsFixed(2)}', Icons.warning_amber_rounded, AppColors.kSecondary, 'Due/credit'),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String subtitle) {
    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: color),
            ]),
            const SizedBox(height: AppSizes.padding),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.kTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by supplier, purchase id, or product name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchController.clear()))
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildList(bool isDesktop, List<Purchase> purchases) {
    if (purchases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48.0),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 72, color: AppColors.kTextSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No purchases found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.kTextSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: purchases.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.padding),
      itemBuilder: (context, index) {
        final p = purchases[index];
        final supplierLabel = p.supplierName ?? (p.supplierId == null ? 'N/A' : 'Supplier #${p.supplierId}');
        final itemsCount = p.items.length;

        final statusColor = switch (p.status) {
          'paid' => AppColors.kSuccess,
          'credited' => AppColors.kSecondary,
          _ => AppColors.kPrimary,
        };

        return AnimatedCard(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: isDesktop
                ? Row(
                    children: [
                      CircleAvatar(backgroundColor: AppColors.kPrimary.withValues(alpha: 0.1), child: Icon(Icons.receipt, color: AppColors.kPrimary)),
                      const SizedBox(width: AppSizes.padding),
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(
                            children: [
                              Text('Purchase #${p.id}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(p.status.toUpperCase()),
                                backgroundColor: statusColor.withValues(alpha: 0.12),
                                labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text('$supplierLabel • $itemsCount items', style: Theme.of(context).textTheme.bodyMedium),
                        ]),
                      ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('\$${p.total.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.kPrimary, fontWeight: FontWeight.bold)),
                          Text('Due: \$${p.dueAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                        ]),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Purchase #${p.id}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text(p.status.toUpperCase()),
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ]),
                      const SizedBox(height: AppSizes.smallPadding),
                      Text('$supplierLabel • $itemsCount items', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSizes.smallPadding),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('\$${p.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.kPrimary, fontWeight: FontWeight.bold)),
                        Text('Due: \$${p.dueAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                      ]),
                    ],
                  ),
          ),
        );
      },
    );
  }
}