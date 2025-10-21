import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';

import 'package:sales_app/features/invoices/bloc/invoice_bloc.dart';
import 'package:sales_app/features/invoices/bloc/invoice_event.dart';
import 'package:sales_app/features/invoices/bloc/invoice_state.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';

class InvoiceOverlayScreen extends StatefulWidget {
  final int invoiceId;
  final VoidCallback? onClose;
  // Called after successful payment so the parent can refresh quietly.
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
  late final AnimationController _fadeIn;
  final _currency = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    // This widget expects a scoped InvoiceBloc provided by the caller (InvoicesScreen)
    context.read<InvoiceBloc>().add(LoadInvoiceDetails(widget.invoiceId));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _fadeIn.dispose();
    super.dispose();
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
          widget.onCommitted?.call(); // refresh parent quietly
        }
        if (state is InvoicesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kError),
          );
        }
      },
      // Rebuild on details loaded, generic loading, or error
      buildWhen: (_, s) => s is InvoiceDetailsLoaded || s is InvoicesLoading || s is InvoicesError,
      builder: (context, state) {
        if (state is InvoicesLoading) {
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
        final paid = payments.fold<double>(0, (s, p) => s + p.amount);
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
                            // Paper-like invoice container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header band
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('INVOICE', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 10,
                                                runSpacing: 6,
                                                children: [
                                                  _MetaPill(icon: Icons.confirmation_number, label: 'Invoice #${inv.id}'),
                                                  _MetaPill(icon: Icons.person, label: 'Customer #${inv.customerId}'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        _StatusBadgeLarge(label: status.label, color: status.color),
                                      ],
                                    ),
                                  ),

                                  // Body sections
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    child: Column(
                                      children: [
                                        if (wide)
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: _SummaryCard(title: 'Total', value: _currency.format(inv.totalAmount), icon: Icons.receipt_long, color: theme.colorScheme.primary)),
                                              const SizedBox(width: 12),
                                              Expanded(child: _SummaryCard(title: 'Paid', value: _currency.format(paid), icon: Icons.payments, color: Colors.green.shade700)),
                                              const SizedBox(width: 12),
                                              Expanded(child: _SummaryCard(title: 'Due', value: _currency.format(due), icon: Icons.pending_actions, color: Colors.orange.shade700)),
                                            ],
                                          )
                                        else
                                          Column(
                                            children: [
                                              _SummaryCard(title: 'Total', value: _currency.format(inv.totalAmount), icon: Icons.receipt_long, color: theme.colorScheme.primary),
                                              const SizedBox(height: 10),
                                              _SummaryCard(title: 'Paid', value: _currency.format(paid), icon: Icons.payments, color: Colors.green.shade700),
                                              const SizedBox(height: 10),
                                              _SummaryCard(title: 'Due', value: _currency.format(due), icon: Icons.pending_actions, color: Colors.orange.shade700),
                                            ],
                                          ),
                                        const SizedBox(height: 16),
                                        _SectionDivider(title: 'Payments'),
                                        const SizedBox(height: 6),
                                        payments.isEmpty
                                            ? Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                                                    const SizedBox(width: 8),
                                                    Text('No payments yet', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                                                  ],
                                                ),
                                              )
                                            : ListView.separated(
                                                physics: const NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: payments.length,
                                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                                itemBuilder: (_, i) {
                                                  final p = payments[i];
                                                  return ListTile(
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                    leading: CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor: Colors.green.withValues(alpha: 0.12),
                                                      child: const Icon(Icons.payments, color: Colors.green, size: 20),
                                                    ),
                                                    title: Text(_currency.format(p.amount), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                                    subtitle: Text(DateFormat.yMMMEd().add_jm().format(p.paidAt.toLocal())),
                                                  );
                                                },
                                              ),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PaymentActionsBar(
                              controller: _amountCtrl,
                              onPayCustom: (amt) => _addPayment(amt, due),
                              onPayDue: due > 0 ? () => _addPayment(due, due) : null,
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
              Icon(Icons.error_outline, size: 36, color: cs.error),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            label == 'PAID' ? Icons.check_circle : label == 'CREDITED' ? Icons.credit_score : Icons.highlight_off,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
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
    final subtle = theme.colorScheme.primary.withValues(alpha: 0.05);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: subtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ]),
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
    final line = Container(height: 1, color: Colors.grey.shade200);
    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );
    return Row(children: [Expanded(child: line), label, Expanded(child: line)]);
  }
}

class _PaymentActionsBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(double?) onPayCustom;
  final VoidCallback? onPayDue;
  final double due;

  const _PaymentActionsBar({
    required this.controller,
    required this.onPayCustom,
    required this.onPayDue,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPayDue == null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Payment amount',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  onSubmitted: (_) => onPayCustom(null),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => onPayCustom(null),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  minimumSize: const Size(120, 48),
                ),
                child: const Text('Add Payment'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled ? null : onPayDue,
                  icon: const Icon(Icons.done_all),
                  label: Text('Pay Due (${NumberFormat.simpleCurrency().format(due)})'),
                ),
              ),
              const SizedBox(width: 8),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}