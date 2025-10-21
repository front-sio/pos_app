import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/features/invoices/bloc/invoice_bloc.dart';
import 'package:sales_app/features/invoices/bloc/invoice_event.dart';
import 'package:sales_app/features/invoices/bloc/invoice_state.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';
import 'package:sales_app/features/invoices/presentation/invoice_overlay_screen.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';

class InvoicesScreen extends StatefulWidget {
  final void Function(Invoice)? onOpenOverlay;
  const InvoicesScreen({super.key, this.onOpenOverlay});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  final Map<int, Customer> _customers = {};
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
        if (c.id != null) _customers[c.id!] = c;
      }
      if (mounted) setState(() {});
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingCustomers = false);
    }
  }

  String _customerName(int id) => _customers[id]?.name ?? 'Customer #$id';

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
      buildWhen: (a, b) => b is InvoicesLoading || b is InvoicesLoaded,
      builder: (context, state) {
        if (state is InvoicesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final invoices = state is InvoicesLoaded ? state.invoices : <Invoice>[];
        final q = _searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? invoices
            : invoices.where((i) {
                final name = _customerName(i.customerId).toLowerCase();
                return name.contains(q) || i.id.toString().contains(q);
              }).toList();

        final paid = filtered.where((i) => i.status == 'paid').toList();
        final unpaid = filtered.where((i) => i.status != 'paid').toList();

        return Padding(
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
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchCtrl.clear()))
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
                    _section('Unpaid', unpaid, context),
                    const SizedBox(height: AppSizes.padding),
                    _section('Paid', paid, context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Invoice> list, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('$title (${list.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                itemBuilder: (_, i) {
                  final inv = list[i];
                  final isPaid = inv.status == 'paid';
                  final color = isPaid ? AppColors.kSuccess : AppColors.kWarning;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(isPaid ? Icons.verified : Icons.warning_amber, color: color),
                    ),
                    title: Text('Invoice #${inv.id} • ${_customerName(inv.customerId)}'),
                    subtitle: Text('Total: \$${inv.totalAmount.toStringAsFixed(2)} • ${inv.createdAt.toLocal()}'),
                    trailing: Chip(
                      label: Text(inv.status.toUpperCase()),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      if (widget.onOpenOverlay != null) {
                        widget.onOpenOverlay!(inv);
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            clipBehavior: Clip.antiAlias,
                            child: SizedBox(
                              width: 520,
                              child: InvoiceOverlayScreen(invoiceId: inv.id),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}