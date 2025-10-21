import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/stocks/bloc/stock_bloc.dart';
import 'package:sales_app/features/stocks/bloc/stock_event.dart';
import 'package:sales_app/features/stocks/bloc/stock_state.dart';
import 'package:sales_app/features/stocks/data/stock_transaction_model.dart';
import 'package:sales_app/features/stocks/presentation/stock_overlay_screen.dart';
import 'package:sales_app/widgets/animated_card.dart';
import 'package:sales_app/widgets/custom_field.dart';

class StockScreen extends StatefulWidget {
  // For transactions (view) this screen will open its own bottom sheet overlay.
  final Future<void> Function(Product product, StockOverlayMode mode)? onOpenOverlay;

  const StockScreen({super.key, this.onOpenOverlay});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _money = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    // Load transactions for view
    context.read<StockBloc>().add(const LoadTransactions(page: 1));
    _searchController.addListener(() {
      context.read<StockBloc>().add(SearchTransactions(_searchController.text));
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Reserved for future pagination when backend supports transactions paging
  void _onScroll() {}

  Future<void> _openTxnOverlay(StockTransaction txn, StockOverlayMode mode) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: StockOverlayScreen(
          mode: mode,
          transaction: txn,
          onSaved: () {
            Navigator.of(context).pop();
            // Refresh list
            context.read<StockBloc>().add(const LoadTransactions(page: 1));
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: CustomInput(
              controller: _searchController,
              label: 'Search Transactions',
              prefixIcon: Icons.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<StockBloc, StockState>(
              builder: (context, state) {
                if (state is StockInitial || state is StockLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is StockLoaded) {
                  final txns = state.filteredTransactions;
                  if (txns.isEmpty) {
                    return const Center(child: Text('No stock transactions found.'));
                  }

                  // Group transactions by productId
                  final Map<int, List<StockTransaction>> grouped = {};
                  for (final t in txns) {
                    grouped.putIfAbsent(t.productId, () => []).add(t);
                  }
                  final productIds = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: productIds.length,
                    itemBuilder: (context, index) {
                      final pid = productIds[index];
                      final list = grouped[pid]!;
                      final name = list.first.productName ?? 'Product #$pid';
                      final totalCost = list.fold<double>(0.0, (sum, t) => sum + t.totalCost);

                      return AnimatedCard(
                        key: ValueKey('group_$pid'),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSizes.padding,
                            vertical: AppSizes.smallPadding,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                            childrenPadding: const EdgeInsets.only(
                              left: AppSizes.padding,
                              right: AppSizes.padding,
                              bottom: AppSizes.padding,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.kPrimary.withValues(alpha: 0.1),
                              child:  Icon(Icons.inventory_2, color: AppColors.kPrimary),
                            ),
                            title: Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Transactions: ${list.length} • Total: ${_money.format(totalCost)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            children: [
                              ...list.map((txn) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Quantity: ${txn.amountAdded.toStringAsFixed(2)} ${txn.unitName ?? ''}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  subtitle: Text(
                                    '${_money.format(txn.totalCost)} • ${DateFormat.yMMMd().add_jm().format(txn.date)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (String value) {
                                      switch (value) {
                                        case 'view':
                                          _openTxnOverlay(txn, StockOverlayMode.view);
                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'view',
                                        child: ListTile(
                                          leading: Icon(Icons.visibility),
                                          title: Text('View'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _openTxnOverlay(txn, StockOverlayMode.view),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is StockError) {
                  return Center(child: Text(state.message));
                }
                return const Center(child: Text('Unknown state'));
              },
            ),
          ),
        ],
      ),
    );
  }
}