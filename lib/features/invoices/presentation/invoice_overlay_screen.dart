import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';

import 'package:sales_app/features/invoices/bloc/invoice_bloc.dart';
import 'package:sales_app/features/invoices/bloc/invoice_event.dart';
import 'package:sales_app/features/invoices/bloc/invoice_state.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';
import 'package:sales_app/features/invoices/services/invoice_services.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';
import 'package:sales_app/features/sales/data/sale_item.dart';

import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';

import 'package:sales_app/features/invoices/services/export_service.dart' as inv_export;
import 'package:sales_app/features/customers/services/customer_services.dart';

class InvoiceOverlayScreen extends StatefulWidget {
  final int invoiceId;
  final VoidCallback? onClose;
  final VoidCallback? onCommitted;

  const InvoiceOverlayScreen({
    super.key,
    required this.invoiceId,
    this.onClose,
    this.onCommitted,
  });

  @override
  State<InvoiceOverlayScreen> createState() => _InvoiceOverlayScreenState();
}

class _InvoiceOverlayScreenState extends State<InvoiceOverlayScreen> with TickerProviderStateMixin {
  final _amountCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  late final AnimationController _fadeIn;
  late final AnimationController _exportLoader;

  bool _loadingReturns = false;
  String _returnsError = '';
  List<_ReturnLine> _returns = const [];
  bool _exportingPdf = false;

  String? _customerNameCache;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _exportLoader = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    context.read<InvoiceBloc>().add(LoadInvoiceDetails(widget.invoiceId));
    _loadReturns();
    _primeCustomerName();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _discountCtrl.dispose();
    _fadeIn.dispose();
    _exportLoader.dispose();
    super.dispose();
  }

  Future<void> _primeCustomerName() async {
    try {
      int? cid;
      final s = context.read<InvoiceBloc>().state;
      if (s is InvoiceDetailsLoaded) {
        cid = s.invoice.customerId;
      } else {
        final inv = await context.read<InvoiceService>().getInvoice(widget.invoiceId);
        cid = inv.customerId;
      }
      if (cid != null && cid > 0) {
        final svc = context.read<CustomerService>();
        final list = await svc.getCustomers(page: 1, limit: 1000);
        if (!mounted) return;
        final found = list.where((e) => e.id == cid).toList();
        if (found.isNotEmpty) {
          setState(() => _customerNameCache = found.first.name);
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadReturns() async {
    setState(() {
      _loadingReturns = true;
      _returnsError = '';
      _returns = const [];
    });

    try {
      final invoiceService = context.read<InvoiceService>();
      final salesService = context.read<SalesService>();

      final saleIds = await invoiceService.getInvoiceSales(widget.invoiceId);
      final List<_ReturnLine> lines = [];
      final Set<String> seen = {};

      for (final saleId in saleIds) {
        final sale = await salesService.getSaleById(saleId);
        final itemsById = <int, SaleItem>{};
        final saleItemIds = <int>{};
        if (sale != null) {
          for (final it in sale.items) {
            final sid = it.id;
            if (sid != null) {
              itemsById[sid] = it;
              saleItemIds.add(sid);
            }
          }
        }

        final returns = await salesService.getReturnsBySaleId(saleId);

        for (final r in returns) {
          if (!saleItemIds.contains(r.saleItemId)) continue;

          final saleItem = itemsById[r.saleItemId];
          final productName = saleItem != null ? _productNameForId(saleItem.productId) : 'Item #${r.saleItemId}';

          final key = '$saleId:${r.saleItemId}:${r.returnedAt.toIso8601String()}:${r.quantityReturned}';
          if (seen.add(key)) {
            lines.add(_ReturnLine(
              productName: productName,
              quantity: r.quantityReturned,
              returnedAt: r.returnedAt,
            ));
          }
        }
      }

      lines.sort((a, b) => b.returnedAt.compareTo(a.returnedAt));
      if (mounted) setState(() => _returns = lines);
    } catch (e) {
      if (mounted) setState(() => _returnsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingReturns = false);
    }
  }

  String _productNameForId(int productId) {
    final st = context.read<ProductsBloc>().state;
    if (st is ProductsLoaded) {
      final match = st.products.where((x) => x.id == productId);
      if (match.isNotEmpty) return match.first.name;
    }
    return 'Product #$productId';
  }

  void _addPayment(double? quickAmount, double due) {
    final input = quickAmount ?? double.tryParse(_amountCtrl.text.trim());
    if (input == null || input <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount'), backgroundColor: AppColors.kError),
      );
      return;
    }
    final amt = input > due ? due : input;
    HapticFeedback.selectionClick();
    context.read<InvoiceBloc>().add(AddPaymentEvent(widget.invoiceId, amt));
    _amountCtrl.clear();
  }

  void _applyDiscount(double total) {
    final input = double.tryParse(_discountCtrl.text.trim());
    if (input == null || input <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid discount amount'), backgroundColor: AppColors.kError),
      );
      return;
    }
    context.read<InvoiceBloc>().add(ApplyDiscountToInvoice(invoiceId: widget.invoiceId, discountAmount: input));
    _discountCtrl.clear();
  }

  Future<void> _exportInvoicePdf(Invoice inv, List<Payment> payments) async {
    if (_exportingPdf) return;
    
    setState(() => _exportingPdf = true);
    
    try {
      final invoiceService = context.read<InvoiceService>();
      final salesService = context.read<SalesService>();

      final saleIds = await invoiceService.getInvoiceSales(inv.id);

      final sections = <inv_export.InvoiceSaleSection>[];

      for (final saleId in saleIds) {
        final sale = await salesService.getSaleById(saleId);
        if (sale == null) continue;

        final returns = await salesService.getReturnsBySaleId(saleId);
        final saleItemIds = sale.items.map((e) => e.id).whereType<int>().toSet();
        final returnedByItem = <int, double>{};
        for (final r in returns) {
          if (!saleItemIds.contains(r.saleItemId)) continue;
          returnedByItem[r.saleItemId] = (returnedByItem[r.saleItemId] ?? 0) + r.quantityReturned.toDouble();
        }

        final lines = <inv_export.InvoiceLineData>[];
        for (final it in sale.items) {
          final sid = it.id;
          if (sid == null) continue;
          final unitPrice = _safeUnitPrice(it);
          final returnedQty = returnedByItem[sid] ?? 0.0;
          final name = _productNameForId(it.productId);

          lines.add(inv_export.InvoiceLineData(
            product: name,
            soldQty: it.quantitySold,
            returnedQty: returnedQty,
            unitPrice: unitPrice,
          ));
        }

        sections.add(inv_export.InvoiceSaleSection(
          saleId: sale.id,
          soldAt: sale.soldAt,
          lines: lines,
        ));
      }

      final paid = payments.fold<double>(0.0, (s, p) => s + p.amount);
      final due = ((inv.totalAmount - paid).clamp(0, double.infinity)).toDouble();
      final statusLabel = _computeStatus(inv.totalAmount, paid).label;
      final status = statusLabel == 'PAID' ? 'Paid' : (statusLabel == 'CREDITED' ? 'Credited' : 'Unpaid');

      final customerName = _customerNameCache ?? 'Customer #${inv.customerId}';

      await inv_export.ExportService.exportInvoicePdf(
        fileName: 'invoice_${inv.id}.pdf',
        invoiceId: inv.id,
        customerName: customerName,
        createdAt: inv.createdAt.toLocal(),
        statusText: status,
        sections: sections,
        amountPaid: paid,
        amountDue: due,
        fmtCurrency: (n) => CurrencyFmt.format(context, n),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice exported successfully'), backgroundColor: AppColors.kSuccess),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.kError),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listenWhen: (_, s) => s is InvoiceOperationSuccess || s is InvoicesError,
      listener: (context, state) {
        if (state is InvoiceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kSuccess),
          );
          widget.onCommitted?.call();
          _loadReturns();
        }
        if (state is InvoicesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kError),
          );
        }
      },
      buildWhen: (_, s) => s is InvoiceDetailsLoaded || s is InvoiceDetailsLoading || s is InvoicesError,
      builder: (context, state) {
        if (state is InvoiceDetailsLoading) {
          return const SizedBox(height: 360, child: Center(child: CircularProgressIndicator()));
        }
        if (state is InvoicesError) {
          return _OverlayError(
            message: state.message,
            onRetry: () => context.read<InvoiceBloc>().add(LoadInvoiceDetails(widget.invoiceId)),
            onClose: widget.onClose,
          );
        }
        if (state is! InvoiceDetailsLoaded) {
          return const SizedBox(height: 360, child: Center(child: Text('Failed to load invoice')));
        }

        final Invoice inv = state.invoice;
        final payments = state.payments;
        final paid = payments.fold<double>(0.0, (s, p) => s + p.amount);
        final double due = ((inv.totalAmount - paid).clamp(0, double.infinity)).toDouble();
        final status = _computeStatus(inv.totalAmount, paid);

        final isWide = MediaQuery.of(context).size.width >= 900;
        final maxBodyWidth = isWide ? 920.0 : double.infinity;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            titleSpacing: 0,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Invoice #${inv.id}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusChip(text: status.label, color: status.color),
                const SizedBox(width: 12),
                _ExportButton(
                  isLoading: _exportingPdf,
                  onPressed: () => _exportInvoicePdf(inv, payments),
                  animationController: _exportLoader,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose ?? () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBodyWidth),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _fadeIn, curve: Curves.easeInOut),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final wide = constraints.maxWidth >= 820;
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Main Invoice Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header Section
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          theme.colorScheme.primary.withValues(alpha: 0.08),
                                          theme.colorScheme.primary.withValues(alpha: 0.03),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'INVOICE',
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.8,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 12,
                                                runSpacing: 8,
                                                children: [
                                                  _MetaPill(icon: Icons.confirmation_number, label: 'Invoice #${inv.id}'),
                                                  _MetaPill(icon: Icons.person, label: _customerNameCache != null ? _customerNameCache! : 'Customer #${inv.customerId}'),
                                                  _MetaPill(icon: Icons.calendar_today, label: DateFormat.yMMMd().format(inv.createdAt.toLocal())),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        _StatusBadgeLarge(label: status.label, color: status.color),
                                      ],
                                    ),
                                  ),

                                  // Content Section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    child: Column(
                                      children: [
                                        if (wide)
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _SummaryCard(
                                                  title: 'Total Amount',
                                                  value: CurrencyFmt.format(context, inv.totalAmount),
                                                  icon: Icons.receipt_long,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: _SummaryCard(
                                                  title: 'Amount Paid',
                                                  value: CurrencyFmt.format(context, paid),
                                                  icon: Icons.check_circle,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: _SummaryCard(
                                                  title: 'Outstanding',
                                                  value: CurrencyFmt.format(context, due),
                                                  icon: Icons.pending_actions,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Column(
                                            children: [
                                              _SummaryCard(
                                                title: 'Total Amount',
                                                value: CurrencyFmt.format(context, inv.totalAmount),
                                                icon: Icons.receipt_long,
                                                color: theme.colorScheme.primary,
                                              ),
                                              const SizedBox(height: 12),
                                              _SummaryCard(
                                                title: 'Amount Paid',
                                                value: CurrencyFmt.format(context, paid),
                                                icon: Icons.check_circle,
                                                color: Colors.green.shade700,
                                              ),
                                              const SizedBox(height: 12),
                                              _SummaryCard(
                                                title: 'Outstanding',
                                                value: CurrencyFmt.format(context, due),
                                                icon: Icons.pending_actions,
                                                color: Colors.orange.shade700,
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 20),

                                        // Payments Section
                                        _SectionDivider(title: 'Payment History'),
                                        const SizedBox(height: 10),
                                        payments.isEmpty
                                            ? _EmptyStateBox(
                                                icon: Icons.payment,
                                                message: 'No payments recorded yet',
                                              )
                                            : ListView.separated(
                                                physics: const NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: payments.length,
                                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                                itemBuilder: (_, i) {
                                                  final p = payments[i];
                                                  return _PaymentListTile(payment: p);
                                                },
                                              ),
                                        const SizedBox(height: 24),

                                        // Returns Section
                                        _SectionDivider(title: 'Returns & Adjustments'),
                                        const SizedBox(height: 10),
                                        if (_loadingReturns)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 24),
                                            child: Center(child: CircularProgressIndicator()),
                                          )
                                        else if (_returnsError.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: Text(_returnsError, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                          )
                                        else if (_returns.isEmpty)
                                          _EmptyStateBox(
                                            icon: Icons.undo,
                                            message: 'No returns recorded',
                                          )
                                        else
                                          ListView.separated(
                                            physics: const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount: _returns.length,
                                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                            itemBuilder: (_, i) {
                                              final r = _returns[i];
                                              return _ReturnListTile(returnLine: r);
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Payment & Discount Actions
                            _PaymentAndDiscountBar(
                              payController: _amountCtrl,
                              discountController: _discountCtrl,
                              onPayCustom: (amt) => _addPayment(amt, due),
                              onPayDue: due > 0 ? () => _addPayment(due, due) : null,
                              onApplyDiscount: () => _applyDiscount(inv.totalAmount),
                              due: due,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _Status _computeStatus(double total, double paid) {
    final t = total <= 0 ? 0 : total;
    if (paid <= 0) {
      return _Status('UNPAID', Colors.red.shade700);
    }
    if (paid >= t && t > 0) {
      return _Status('PAID', Colors.green.shade700);
    }
    return _Status('CREDITED', Colors.orange.shade700);
  }

  double _safeUnitPrice(SaleItem item) {
    if (item.salePricePerQuantity != 0) return item.salePricePerQuantity;
    final q = item.quantitySold;
    if (q > 0) return _safeLineTotal(item, allowRecurse: false) / q;
    return 0.0;
  }

  double _safeLineTotal(SaleItem item, {bool allowRecurse = true}) {
    if (item.totalSalePrice != 0) return item.totalSalePrice;
    if (allowRecurse) return _safeUnitPrice(item) * item.quantitySold;
    return 0.0;
  }
}

class _ReturnLine {
  final String productName;
  final int quantity;
  final DateTime returnedAt;

  _ReturnLine({
    required this.productName,
    required this.quantity,
    required this.returnedAt,
  });
}

class _OverlayError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onClose;
  const _OverlayError({required this.message, required this.onRetry, this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Invoice'),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: onClose ?? () => Navigator.pop(context)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Status {
  final String label;
  final Color color;
  const _Status(this.label, this.color);
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusBadgeLarge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadgeLarge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'PAID' ? Icons.check_circle : label == 'CREDITED' ? Icons.credit_score : Icons.highlight_off,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String title;
  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    final line = Container(height: 1.5, color: Colors.grey.shade200);
    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade800,
        ),
      ),
    );
    return Row(children: [Expanded(child: line), label, Expanded(child: line)]);
  }
}

class _EmptyStateBox extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyStateBox({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _PaymentListTile extends StatelessWidget {
  final Payment payment;
  const _PaymentListTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.green.withValues(alpha: 0.15),
        child: const Icon(Icons.check_circle, color: Colors.green, size: 22),
      ),
      title: Text(
        CurrencyFmt.format(context, payment.amount),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        DateFormat.yMMMEd().add_jm().format(payment.paidAt.toLocal()),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.arrow_forward, size: 18, color: Colors.grey.shade400),
    );
  }
}

class _ReturnListTile extends StatelessWidget {
  final _ReturnLine returnLine;
  const _ReturnListTile({required this.returnLine});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.orange.withValues(alpha: 0.15),
        child: const Icon(Icons.undo, color: Colors.orange, size: 22),
      ),
      title: Text(
        '${returnLine.productName} • Qty: ${returnLine.quantity}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        DateFormat.yMMMEd().add_jm().format(returnLine.returnedAt.toLocal()),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.arrow_forward, size: 18, color: Colors.grey.shade400),
    );
  }
}

class _PaymentAndDiscountBar extends StatelessWidget {
  final TextEditingController payController;
  final TextEditingController discountController;
  final void Function(double?) onPayCustom;
  final VoidCallback? onPayDue;
  final VoidCallback onApplyDiscount;
  final double due;

  const _PaymentAndDiscountBar({
    required this.payController,
    required this.discountController,
    required this.onPayCustom,
    required this.onPayDue,
    required this.onApplyDiscount,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPayDue == null;
    final isNarrow = MediaQuery.of(context).size.width < 420;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isNarrow) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discountController,
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      prefixIcon: const Icon(Icons.local_offer),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: onApplyDiscount,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(110, 48),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: payController,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => onPayCustom(null),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => onPayCustom(null),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  minimumSize: const Size(130, 48),
                ),
                child: const Text('Add Payment', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: disabled ? null : onPayDue,
                  icon: const Icon(Icons.done_all),
                  label: Text('Pay Full Due (${CurrencyFmt.format(context, due)})'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: due > 0
                      ? () {
                          final half = ((due * 0.5).clamp(0.0, due) as num).toDouble();
                          onPayCustom(half);
                        }
                      : null,
                  icon: const Icon(Icons.payments),
                  label: const Text('Pay 50%'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(110, 48),
                  ),
                ),
              ),
            ],
          ),
          if (!isNarrow) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discountController,
                    decoration: InputDecoration(
                      labelText: 'Discount Amount',
                      prefixIcon: const Icon(Icons.local_offer),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: onApplyDiscount,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(110, 48),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final AnimationController animationController;

  const _ExportButton({
    required this.isLoading,
    required this.onPressed,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Tooltip(
          message: 'Download Invoice PDF',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Icon(
                        Icons.picture_as_pdf,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      isLoading ? 'Exporting...' : 'Export PDF',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}