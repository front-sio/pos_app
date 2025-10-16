import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/invoices/bloc/invoice_bloc.dart';
import 'package:sales_app/features/invoices/bloc/invoice_event.dart';
import 'package:sales_app/features/invoices/bloc/invoice_state.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';

class InvoiceOverlayScreen extends StatefulWidget {
  final int invoiceId;
  final VoidCallback? onClose;

  const InvoiceOverlayScreen({super.key, required this.invoiceId, this.onClose});

  @override
  State<InvoiceOverlayScreen> createState() => _InvoiceOverlayScreenState();
}

class _InvoiceOverlayScreenState extends State<InvoiceOverlayScreen> {
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(LoadInvoiceDetails(widget.invoiceId));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _addPayment() {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount'), backgroundColor: AppColors.kError),
      );
      return;
    }
    context.read<InvoiceBloc>().add(AddPaymentEvent(widget.invoiceId, amt));
    _amountCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listenWhen: (_, s) => s is InvoiceOperationSuccess || s is InvoicesError,
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
      buildWhen: (_, s) => s is InvoicesLoading || s is InvoiceDetailsLoaded,
      builder: (context, state) {
        if (state is InvoicesLoading) {
          return const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()));
        }
        if (state is! InvoiceDetailsLoaded) {
          return const SizedBox(height: 320, child: Center(child: Text('Failed to load')));
        }

        final Invoice inv = state.invoice;
        final payments = state.payments;
        final paid = payments.fold<double>(0, (s, p) => s + p.amount);
        final due = (inv.totalAmount - paid).clamp(0, double.infinity);
        final isPaid = paid >= inv.totalAmount;

        final statusColor = isPaid ? AppColors.kSuccess : AppColors.kWarning;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('Invoice #${inv.id}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose ?? () => Navigator.pop(context),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Chip(
                    label: Text(isPaid ? 'PAID' : 'UNPAID'),
                    backgroundColor: statusColor.withOpacity(0.12),
                    labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text('Customer #${inv.customerId}', style: Theme.of(context).textTheme.titleMedium),
                ]),
                const SizedBox(height: AppSizes.smallPadding),
                Text('Total: \$${inv.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                Text('Paid: \$${paid.toStringAsFixed(2)}'),
                Text('Due: \$${due.toStringAsFixed(2)}'),
                const SizedBox(height: AppSizes.padding),
                Text('Payments', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: payments.isEmpty
                      ? const Center(child: Text('No payments yet'))
                      : ListView.separated(
                          itemCount: payments.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                          itemBuilder: (_, i) {
                            final p = payments[i];
                            return ListTile(
                              leading: const Icon(Icons.payments),
                              title: Text('\$${p.amount.toStringAsFixed(2)}'),
                              subtitle: Text(p.paidAt.toLocal().toString()),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSizes.smallPadding),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Payment amount',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addPayment,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimary),
                      child: const Text('Add Payment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}