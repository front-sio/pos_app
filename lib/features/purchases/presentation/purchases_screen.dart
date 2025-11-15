import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';
import 'package:sales_app/widgets/animated_card.dart';
import 'package:sales_app/widgets/responsive_grid.dart';
import 'package:sales_app/widgets/api_error_screen.dart';

import 'package:sales_app/features/purchases/bloc/purchase_bloc.dart';
import 'package:sales_app/features/purchases/bloc/purchase_event.dart';
import 'package:sales_app/features/purchases/bloc/purchase_state.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';

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
                        const SnackBar(
                          content: Text('Operation completed successfully'),
                          backgroundColor: AppColors.kSuccess,
                        ),
                      );
                    }
                    if (state is PurchaseError && !state.isNetworkError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to complete operation. Please try again.'),
                          backgroundColor: AppColors.kError,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  buildWhen: (prev, curr) => curr is PurchaseLoading || curr is PurchaseLoaded || curr is PurchaseError,
                  builder: (context, state) {
                    // Show API error screen for network errors on initial load
                    if (state is PurchaseError && state.isNetworkError && _lastKnownPurchases.isEmpty) {
                      return ApiErrorScreen(
                        errorMessage: state.message,
                        endpoint: '/products/purchases',
                        onRetry: () {
                          context.read<PurchaseBloc>().add(const LoadPurchases());
                        },
                      );
                    }

                    if (state is PurchaseLoading && _lastKnownPurchases.isEmpty) {
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

                    final baseSorted = [...purchases]
                      ..sort((a, b) {
                        final byDate = b.date.compareTo(a.date);
                        if (byDate != 0) return byDate;
                        return b.id.compareTo(a.id);
                      });

                    final filtered = _applySearch(baseSorted);
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
      final supplierLabel = (p.supplierName ?? (p.supplierId == null ? 'N/A' : 'Supplier #${p.supplierId}')).toLowerCase();
      final idMatch = p.id.toString().contains(q);
      final itemNames = p.items.map((i) => (i.productName ?? '')).join(' ').toLowerCase();
      return supplierLabel.contains(q) || idMatch || itemNames.contains(q);
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
          Text(
            'Track multi-item supplier purchases and payments',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.kTextSecondary),
          ),
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
        _statCard(
          'Total Spend',
          CurrencyFmt.format(context, totalSpend),
          Icons.payments,
          AppColors.kPrimary,
          '$totalOrders orders',
        ),
        _statCard(
          'Paid',
          CurrencyFmt.format(context, paidSpend),
          Icons.check_circle,
          AppColors.kSuccess,
          'Settled',
        ),
        _statCard(
          'Outstanding',
          CurrencyFmt.format(context, due),
          Icons.warning_amber_rounded,
          AppColors.kSecondary,
          'Due/credit',
        ),
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

        final meta = _statusMeta(p.status, p.paidAmount, p.total);
        final canPay = p.dueAmount > 0.0;

        final tile = Container(
          padding: const EdgeInsets.all(AppSizes.padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: meta.color.withValues(alpha: 0.12),
                        child: Icon(meta.icon, color: meta.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('Purchase #${p.id}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _StatusBadge(meta: meta),
                ],
              ),
              const SizedBox(height: AppSizes.smallPadding),

              // Supplier and items count
              Text('$supplierLabel • $itemsCount items', style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: AppSizes.smallPadding),

              // Amounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountKV(context, 'Total', p.total, AppColors.kPrimary),
                  _amountKV(context, 'Paid', p.paidAmount, Colors.green),
                  _amountKV(context, 'Due', p.dueAmount, meta.color),
                ],
              ),

              const SizedBox(height: 10),

              // Progress bar showing paid ratio
              _PaymentProgressBar(
                paid: p.paidAmount,
                total: p.total,
                color: meta.color,
              ),

              if (canPay) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openPaymentSheet(p),
                    icon: const Icon(Icons.payments),
                    label: const Text('Pay'),
                  ),
                ),
              ],
            ],
          ),
        );

        // Accent border at left with status color
        return AnimatedCard(
          child: Stack(
            children: [
              tile,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: meta.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.borderRadius),
                      bottomLeft: Radius.circular(AppSizes.borderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPaymentSheet(Purchase p) async {
    final result = await showModalBottomSheet<_PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(purchase: p),
    );

    if (result == null) return;

    final double newPaidAbsolute =
        ((p.paidAmount + result.amount).clamp(0.0, p.total)).toDouble(); // cap to total

    final String finalStatus;
    if (result.statusOverride != null) {
      finalStatus = result.statusOverride!;
    } else {
      finalStatus = (newPaidAbsolute >= p.total)
          ? 'paid'
          : (newPaidAbsolute > 0 ? 'credited' : 'unpaid');
    }

    context.read<PurchaseBloc>().add(
          UpdatePurchasePayment(
            purchaseId: p.id,
            newPaidAmountAbsolute: newPaidAbsolute,
            statusOverride: finalStatus,
          ),
        );
  }
}

/* ----------------------------- Status helpers ------------------------------ */

class _StatusMeta {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusMeta({required this.label, required this.color, required this.icon});
}

_StatusMeta _statusMeta(String status, double paid, double total) {
  final s = status.toLowerCase().trim();
  if (s == 'paid') {
    return _StatusMeta(label: 'PAID', color: Colors.green.shade700, icon: Icons.check_circle);
  }
  if (s == 'credited') {
    return _StatusMeta(label: 'CREDITED', color: Colors.orange.shade700, icon: Icons.credit_card);
  }
  if (paid <= 0) {
    return _StatusMeta(label: 'UNPAID', color: Colors.red.shade700, icon: Icons.highlight_off);
  }
  return _StatusMeta(label: 'CREDITED', color: Colors.orange.shade700, icon: Icons.credit_card);
}

class _StatusBadge extends StatelessWidget {
  final _StatusMeta meta;
  const _StatusBadge({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(meta.icon, size: 16, color: meta.color),
      label: Text(meta.label),
      labelStyle: TextStyle(color: meta.color, fontWeight: FontWeight.bold),
      backgroundColor: meta.color.withValues(alpha: 0.12),
      side: BorderSide(color: meta.color.withValues(alpha: 0.16)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PaymentProgressBar extends StatelessWidget {
  final double paid;
  final double total;
  final Color color;

  const _PaymentProgressBar({required this.paid, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 1.0 : (paid / total).clamp(0.0, 1.0);
    final bg = Theme.of(context).colorScheme.outlineVariant;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: bg),
            FractionallySizedBox(
              widthFactor: ratio,
              alignment: Alignment.centerLeft,
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ UI utilities ------------------------------- */

Widget _amountKV(BuildContext context, String label, double value, Color color) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(
        CurrencyFmt.format(context, value),
        style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

/* --------------------------- Payment bottom sheet -------------------------- */

class _PaymentSheet extends StatefulWidget {
  final Purchase purchase;
  const _PaymentSheet({required this.purchase});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amountCtrl = TextEditingController();
  String? _statusOverride;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = widget.purchase;
    final due = (p.total - p.paidAmount).clamp(0, double.infinity);
    final meta = _statusMeta(p.status, p.paidAmount, p.total);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Material(
          color: theme.cardColor,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: meta.color.withValues(alpha: 0.12),
                        child: Icon(meta.icon, color: meta.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('Pay Purchase #${p.id}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _StatusBadge(meta: meta),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p.supplierName ?? (p.supplierId == null ? 'N/A' : 'Supplier #${p.supplierId}')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _kv('Total', CurrencyFmt.format(context, p.total), theme)),
                      Expanded(child: _kv('Paid', CurrencyFmt.format(context, p.paidAmount), theme)),
                      Expanded(child: _kv('Due', CurrencyFmt.format(context, due), theme)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PaymentProgressBar(paid: p.paidAmount, total: p.total, color: meta.color),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _statusOverride,
                    items: const [
                      DropdownMenuItem(value: 'paid', child: Text('Mark as Paid')),
                      DropdownMenuItem(value: 'credited', child: Text('Mark as Credited')),
                      DropdownMenuItem(value: 'unpaid', child: Text('Mark as Unpaid')),
                    ],
                    onChanged: (v) => setState(() => _statusOverride = v),
                    decoration: const InputDecoration(
                      labelText: 'Status (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.onSurfaceVariant,
                            side: BorderSide(color: cs.outline),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter a valid payment amount')),
                              );
                              return;
                            }
                            Navigator.pop(context, _PaymentResult(amount: amount, statusOverride: _statusOverride));
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(v, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _PaymentResult {
  final double amount;
  final String? statusOverride;
  _PaymentResult({required this.amount, this.statusOverride});
}