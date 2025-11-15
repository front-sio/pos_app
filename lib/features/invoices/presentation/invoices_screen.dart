import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';
import 'package:sales_app/widgets/error_placeholder.dart';

import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';

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

class _InvoicesScreenState extends State<InvoicesScreen> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final Map<int, Customer> _customers = {};

  List<Invoice> _lastKnown = const <Invoice>[];
  bool _loadingCustomers = false;
  late AnimationController _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    context.read<InvoiceBloc>().add(const LoadInvoices());
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeIn.dispose();
    super.dispose();
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
    if (widget.onOpenOverlay != null) {
      widget.onOpenOverlay!(inv);
      return;
    }

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
            onCommitted: () => context.read<InvoiceBloc>().add(const LoadInvoices()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listenWhen: (a, b) => b is InvoiceOperationSuccess || b is InvoicesError,
      listener: (context, state) {
        if (state is InvoiceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operation completed successfully'),
              backgroundColor: AppColors.kSuccess,
            ),
          );
        }
        if (state is InvoicesError && !state.isNetworkError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to complete operation. Please try again.'),
              backgroundColor: AppColors.kError,
            ),
          );
        }
      },
      buildWhen: (a, b) => b is InvoicesLoading || b is InvoicesLoaded || b is InvoicesError,
      builder: (context, state) {
        List<Invoice> source = _lastKnown;
        bool showRefreshingBar = false;

        if (state is InvoicesLoaded) {
          source = state.invoices;
          _lastKnown = source;
        } else if (state is InvoicesLoading) {
          if (_lastKnown.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          showRefreshingBar = true;
        } else if (state is InvoicesError) {
          if (_lastKnown.isEmpty) {
            return ErrorPlaceholder(
              onRetry: () async => await _refresh(),
            );
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to refresh data. Please try again.'),
                  backgroundColor: AppColors.kError,
                ),
              );
            });
            source = _lastKnown;
          }
        }

        final q = _searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? [...source]
            : source.where((i) {
                final name = _customerName(i.customerId).toLowerCase();
                return name.contains(q) || i.id.toString().contains(q);
              }).toList();

        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final unpaidOrCredited = filtered.where((i) => i.status.toLowerCase() != 'paid').toList();
        final paid = filtered.where((i) => i.status.toLowerCase() == 'paid').toList();

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.kPrimary,
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _fadeIn, curve: Curves.easeInOut),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 24 : AppSizes.padding),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invoices',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage and track all your invoices',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.kPrimary.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  '${filtered.length} ${filtered.length == 1 ? 'Invoice' : 'Invoices'}',
                                  style: TextStyle(
                                    color: AppColors.kPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search by customer name or invoice #...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey.shade500),
                                      onPressed: () => setState(() => _searchCtrl.clear()),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        if (_loadingCustomers)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.kPrimary),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Sections
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _section(
                                  context,
                                  'Pending Payment',
                                  unpaidOrCredited,
                                  _openOverlayWithScopedBloc,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _section(
                                  context,
                                  'Completed',
                                  paid,
                                  _openOverlayWithScopedBloc,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _section(
                                context,
                                'Pending Payment',
                                unpaidOrCredited,
                                _openOverlayWithScopedBloc,
                              ),
                              const SizedBox(height: 16),
                              _section(
                                context,
                                'Completed',
                                paid,
                                _openOverlayWithScopedBloc,
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showRefreshingBar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.kPrimary),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Invoice> list,
    void Function(Invoice) onTap,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.kPrimary.withValues(alpha: 0.08),
                  AppColors.kPrimary.withValues(alpha: 0.03),
                ],
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    list.length.toString(),
                    style: TextStyle(
                      color: AppColors.kPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      'No invoices',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.withValues(alpha: 0.1),
                indent: 56,
              ),
              itemBuilder: (_, i) => _InvoiceCard(
                invoice: list[i],
                customerName: _customerName(list[i].customerId),
                timeAgo: _timeAgo(list[i].createdAt.toLocal()),
                statusColor: _statusColor(list[i].status),
                statusIcon: _statusIcon(list[i].status),
                onTap: () => onTap(list[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatefulWidget {
  final Invoice invoice;
  final String customerName;
  final String timeAgo;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.customerName,
    required this.timeAgo,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = widget.invoice.status.toLowerCase() == 'paid' ? 1.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _hovered ? Colors.grey.shade50 : Colors.white,
        ),
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(widget.statusIcon, color: widget.statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Invoice #${widget.invoice.id}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: widget.statusColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              widget.invoice.status.toUpperCase(),
                              style: TextStyle(
                                color: widget.statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.customerName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    CurrencyFmt.format(context, widget.invoice.totalAmount),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                widget.timeAgo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.statusColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_hovered)
                  Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}