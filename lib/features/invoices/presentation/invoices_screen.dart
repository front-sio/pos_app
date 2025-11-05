import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';

// Customers
import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';

// Invoices
import 'package:sales_app/features/invoices/bloc/invoice_bloc.dart';
import 'package:sales_app/features/invoices/bloc/invoice_event.dart';
import 'package:sales_app/features/invoices/bloc/invoice_state.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';
import 'package:sales_app/features/invoices/presentation/invoice_overlay_screen.dart';
import 'package:sales_app/features/invoices/services/invoice_services.dart';

class InvoicesScreen extends StatefulWidget {
  final void Function(Invoice)? onOpenOverlay;
  const InvoicesScreen({super.key, this.onOpenOverlay});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  final Map<int, Customer> _customers = {};

  // Cache last known list to avoid full-screen loader during refresh
  List<Invoice> _lastKnown = const <Invoice>[];
  bool _loadingCustomers = false;

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(const LoadInvoices());
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    try {
      final svc = context.read<CustomerService>();
      final list = await svc.getCustomers(page: 1, limit: 1000);
      for (final c in list) {
        _customers[c.id] = c;
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _loadingCustomers = false);
    }
  }

  String _customerName(int id) => _customers[id]?.name ?? 'Customer #$id';

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green.shade700;
      case 'credited':
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'credited':
        return Icons.credit_card;
      default:
        return Icons.highlight_off;
    }
  }

  Future<void> _refresh() async {
    context.read<InvoiceBloc>().add(const LoadInvoices());
  }

  void _openOverlayWithScopedBloc(Invoice inv) {
    // If a parent handler exists, use it
    if (widget.onOpenOverlay != null) {
      widget.onOpenOverlay!(inv);
      return;
    }
    // IMPORTANT: Use a scoped bloc so overlay loading/errors don’t affect the list
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocProvider<InvoiceBloc>(
          create: (bctx) => InvoiceBloc(service: bctx.read<InvoiceService>())
            ..add(LoadInvoiceDetails(inv.id)),
          child: InvoiceOverlayScreen(
            invoiceId: inv.id,
            onClose: () => Navigator.of(modalCtx).pop(),
            // Only refresh the parent list after a successful payment
            onCommitted: () => context.read<InvoiceBloc>().add(const LoadInvoices()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listenWhen: (a, b) => b is InvoiceOperationSuccess || b is InvoicesError,
      listener: (context, state) {
        if (state is InvoiceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kSuccess),
          );
        }
        if (state is InvoicesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kError),
          );
        }
      },
      // Include error states so UI never gets stuck on a spinner
      buildWhen: (a, b) => b is InvoicesLoading || b is InvoicesLoaded || b is InvoicesError,
      builder: (context, state) {
        // Determine the data source and whether to show a lightweight refresh bar
        List<Invoice> source = _lastKnown;
        bool showRefreshingBar = false;

        if (state is InvoicesLoaded) {
          source = state.invoices;
          _lastKnown = source;
        } else if (state is InvoicesLoading) {
          // If we have no cache yet, show a blocking loader
          if (_lastKnown.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // Else: keep showing cached list and a top thin progress bar
          showRefreshingBar = true;
        } else if (state is InvoicesError) {
          // If we have cache, show it with an error banner; else show error with retry button
          if (_lastKnown.isEmpty) {
            return _TopLevelError(message: state.message, onRetry: _refresh);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.kError),
              );
            });
            source = _lastKnown;
          }
        }

        // Apply search
        final q = _searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? [...source]
            : source.where((i) {
                final name = _customerName(i.customerId).toLowerCase();
                return name.contains(q) || i.id.toString().contains(q);
              }).toList();

        // Sort newest first by createdAt if available
        filtered.sort((a, b) {
          final ad = a.createdAt;
          final bd = b.createdAt;
          return bd.compareTo(ad);
        });

        final unpaidOrCredited = filtered.where((i) => i.status.toLowerCase() != 'paid').toList();
        final paid = filtered.where((i) => i.status.toLowerCase() == 'paid').toList();

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.kPrimary,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search invoices by customer or invoice #',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() => _searchCtrl.clear()),
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    if (_loadingCustomers) const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: AppSizes.padding),
                    Expanded(
                      child: ListView(
                        children: [
                          _section(context, 'Unpaid / Credited', unpaidOrCredited),
                          const SizedBox(height: AppSizes.padding),
                          _section(context, 'Paid', paid),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showRefreshingBar)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, List<Invoice> list) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('$title (${list.length})', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: AppSizes.smallPadding),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No invoices')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
                itemBuilder: (_, i) {
                  final inv = list[i];
                  final statusColor = _statusColor(inv.status);
                  final statusIcon = _statusIcon(inv.status);
                  final created = inv.createdAt.toLocal();
                  final createdText = _timeAgo(created);

                  // Status-based progress (1.0 if paid, else 0.0). Can extend to real paid/due later.
                  final double ratio = inv.status.toLowerCase() == 'paid' ? 1.0 : 0.0;

                  return InkWell(
                    onTap: () => _openOverlayWithScopedBloc(inv),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(statusIcon, color: statusColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Invoice #${inv.id} • ${_customerName(inv.customerId)}',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(inv.status.toUpperCase()),
                                      backgroundColor: statusColor.withValues(alpha: 0.12),
                                      labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.payments, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Total: ${CurrencyFmt.format(context, inv.totalAmount)}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const Text('•'),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(createdText, style: theme.textTheme.bodyMedium),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: SizedBox(
                                    height: 8,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Container(color: Colors.grey.withValues(alpha: 0.14)),
                                        FractionallySizedBox(
                                          widthFactor: ratio,
                                          alignment: Alignment.centerLeft,
                                          child: Container(color: statusColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TopLevelError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _TopLevelError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: cs.error),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}