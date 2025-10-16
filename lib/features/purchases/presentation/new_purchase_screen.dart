import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';
import 'package:sales_app/features/purchases/bloc/purchase_bloc.dart';
import 'package:sales_app/features/purchases/bloc/purchase_event.dart';
import 'package:sales_app/features/purchases/bloc/purchase_state.dart';

class NewPurchaseScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const NewPurchaseScreen({super.key, this.onSaved, this.onCancel});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _LineItemVM {
  Product? product;
  final qtyCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_LineItemVM> _lines = [ _LineItemVM() ];

  // Supplier + status
  final _supplierSearchCtrl = TextEditingController();
  List<SupplierOption> _supplierOptions = [];
  SupplierOption? _selectedSupplier;
  bool _loadingSuppliers = false;

  String _status = 'unpaid'; // paid | unpaid | credited
  final _paidAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _supplierSearchCtrl.dispose();
    _paidAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loadingSuppliers = true);
    try {
      final ps = context.read<ProductService>();
      final list = await ps.getSuppliers();
      setState(() => _supplierOptions = list);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingSuppliers = false);
    }
  }

  void _addLine() => setState(() => _lines.add(_LineItemVM()));
  void _removeLine(int idx) => setState(() {
    final removed = _lines.removeAt(idx);
    removed.dispose();
    if (_lines.isEmpty) _lines.add(_LineItemVM());
  });

  double _computeSubtotal() {
    double total = 0;
    for (final l in _lines) {
      final q = int.tryParse(l.qtyCtrl.text.trim()) ?? 0;
      final p = double.tryParse(l.priceCtrl.text.trim()) ?? 0.0;
      total += q * p;
    }
    return total;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // At least one valid line
    final items = <Map<String, dynamic>>[];
    for (final l in _lines) {
      if (l.product == null) continue;
      final q = int.tryParse(l.qtyCtrl.text.trim()) ?? 0;
      final p = double.tryParse(l.priceCtrl.text.trim()) ?? 0.0;
      if (q > 0 && p > 0) {
        items.add({
          'product_id': l.product!.id,
          'quantity': q,
          'price_per_unit': p,
        });
      }
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one valid line item'), backgroundColor: AppColors.kError));
      return;
    }

    final paidAmt = _paidAmountCtrl.text.trim().isEmpty ? null : double.tryParse(_paidAmountCtrl.text.trim());

    setState(() => _submitting = true);
    context.read<PurchaseBloc>().add(CreatePurchase(
      supplierId: _selectedSupplier?.id,
      status: _status,
      paidAmount: paidAmt,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: items,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        title: const Text('New Purchase'),
        backgroundColor: AppColors.kPrimary,
        foregroundColor: AppColors.kTextOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
            tooltip: 'Close',
          ),
        ],
      ),
      body: BlocConsumer<PurchaseBloc, dynamic>(
        listener: (context, state) {
          if (state is PurchaseError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.kError));
            setState(() => _submitting = false);
          }
          if (state is PurchaseOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.kSuccess));
            setState(() => _submitting = false);
            widget.onSaved?.call();
          }
        },
        builder: (context, state) {
          final isSmall = MediaQuery.of(context).size.width < AppSizes.mobileBreakpoint;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 2),
            child: Form(
              key: _formKey,
              child: Container(
                padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 1.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Supplier & Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.padding),

                    // Supplier selector
                    _buildSupplierSelector(),

                    const SizedBox(height: AppSizes.padding),
                    Row(
                      children: [
                        Expanded(child: _buildStatusDropdown()),
                        const SizedBox(width: AppSizes.padding),
                        Expanded(child: _buildPaidAmount()),
                      ],
                    ),
                    const SizedBox(height: AppSizes.padding),
                    _buildNotes(),

                    const SizedBox(height: AppSizes.padding * 1.5),
                    Text('Line Items', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.smallPadding),
                    ..._lines.asMap().entries.map((e) => _buildLineItem(e.key, e.value)),
                    const SizedBox(height: AppSizes.smallPadding),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line'),
                      ),
                    ),
                    const SizedBox(height: AppSizes.padding),
                    _buildTotals(),

                    const SizedBox(height: AppSizes.padding * 1.5),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting ? null : widget.onCancel,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSizes.padding),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: const Icon(Icons.save),
                            label: Text(_submitting ? 'Saving...' : 'Save Purchase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supplier', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.smallPadding),
        if (_selectedSupplier != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.kPrimary.withValues(alpha: 0.08),
              child: Icon(Icons.local_shipping, color: AppColors.kPrimary),
            ),
            title: Text(_selectedSupplier!.name, overflow: TextOverflow.ellipsis),
            subtitle: Text('ID: ${_selectedSupplier!.id}'),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedSupplier = null),
            ),
          )
        else
          Column(
            children: [
              TextField(
                controller: _supplierSearchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search supplier',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSizes.smallPadding),
              SizedBox(
                height: 180,
                child: _loadingSuppliers
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSupplierList(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSupplierList() {
    final q = _supplierSearchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _supplierOptions
        : _supplierOptions.where((s) => s.name.toLowerCase().contains(q)).toList();

    if (filtered.isEmpty) return const Center(child: Text('No suppliers found'));

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = filtered[index];
        return ListTile(
          leading: const Icon(Icons.local_shipping),
          title: Text(s.name, overflow: TextOverflow.ellipsis),
          subtitle: Text('ID: ${s.id}'),
          onTap: () => setState(() => _selectedSupplier = s),
        );
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      items: const [
        DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
        DropdownMenuItem(value: 'paid', child: Text('Paid')),
        DropdownMenuItem(value: 'credited', child: Text('Credited')),
      ],
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.assignment_turned_in_outlined),
      ),
      onChanged: (v) => setState(() => _status = v ?? 'unpaid'),
    );
  }

  Widget _buildPaidAmount() {
    return TextFormField(
      controller: _paidAmountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      decoration: const InputDecoration(
        labelText: 'Paid Amount (optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payments_outlined),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        final d = double.tryParse(v);
        if (d == null || d < 0) return 'Enter a valid amount';
        return null;
      },
    );
  }

  Widget _buildNotes() {
    return TextFormField(
      controller: _notesCtrl,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.sticky_note_2_outlined),
      ),
    );
  }

  Widget _buildLineItem(int index, _LineItemVM vm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: _buildProductDropdown(vm)),
          const SizedBox(width: AppSizes.smallPadding),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: vm.qtyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Qty';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSizes.smallPadding),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: vm.priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0) return 'Price';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSizes.smallPadding),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: () => _removeLine(index),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(_LineItemVM vm) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, pState) {
        if (pState is ProductsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (pState is ProductsLoaded) {
          return DropdownButtonFormField<Product>(
            value: vm.product,
            items: pState.products
                .map((p) => DropdownMenuItem<Product>(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Product',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            onChanged: (val) => setState(() => vm.product = val),
            validator: (val) => val == null ? 'Product' : null,
          );
        }
        return const Text('Products not loaded');
      },
    );
  }

  Widget _buildTotals() {
    final subtotal = _computeSubtotal();
    return Row(
      children: [
        Expanded(
          child: Text(
            'Subtotal: \$${subtotal.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}