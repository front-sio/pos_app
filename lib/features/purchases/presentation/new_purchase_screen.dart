import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';

import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_event.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';

import 'package:sales_app/features/purchases/bloc/purchase_bloc.dart';
import 'package:sales_app/features/purchases/bloc/purchase_event.dart';
import 'package:sales_app/features/purchases/bloc/purchase_state.dart';

// Settings (to infer fraction digits for money inputs)
import 'package:sales_app/features/settings/bloc/settings_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_state.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';

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

  int get qty => int.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get price => double.tryParse(priceCtrl.text.trim()) ?? 0.0;
  double get lineTotal => qty * price;
  bool get isValid => product != null && qty > 0 && price > 0;
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_LineItemVM> _lines = [_LineItemVM()];

  final _supplierSearchCtrl = TextEditingController();
  List<SupplierOption> _supplierOptions = [];
  SupplierOption? _selectedSupplier;
  bool _loadingSuppliers = false;

  String _status = 'unpaid';
  final _paidAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _loadProducts();
  }

  void _loadProducts() {
    final bloc = context.read<ProductsBloc>();
    if (bloc.state is! ProductsLoaded) {
      bloc.add(FetchProducts());
    }
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
      total += l.lineTotal;
    }
    return total;
  }

  List<_LineItemVM> _validPreviewLines() {
    return _lines.where((l) => l.isValid).toList();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final items = <Map<String, dynamic>>[];
    for (final l in _lines) {
      if (l.isValid) {
        items.add({
          'product_id': l.product!.id,
          'quantity': l.qty,
          'price_per_unit': l.price,
        });
      }
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one valid line item'), backgroundColor: AppColors.kError),
      );
      return;
    }

    final paidAmt = _paidAmountCtrl.text.trim().isEmpty ? null : double.tryParse(_paidAmountCtrl.text.trim());

    setState(() => _submitting = true);
    context.read<PurchaseBloc>().add(
          CreatePurchase(
            supplierId: _selectedSupplier?.id,
            status: _status,
            paidAmount: paidAmt,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            items: items,
          ),
        );
  }

  int _fractionDigits(BuildContext context) {
    final st = context.read<SettingsBloc>().state;
    if (st is SettingsLoaded) return st.settings.fractionDigits;
    if (st is SettingsSaved) return st.settings.fractionDigits;
    return AppSettings.fallback.fractionDigits;
  }

  List<TextInputFormatter> _moneyInputFormatters(BuildContext context) {
    final digits = _fractionDigits(context);
    if (digits <= 0) return [FilteringTextInputFormatter.digitsOnly];
    return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,' + digits.toString() + r'}$'))];
  }

  String _moneyHint(BuildContext context) {
    final d = _fractionDigits(context);
    return d <= 0 ? '0' : '0.${'0' * d}';
  }

  String _currencySymbol(BuildContext context) {
    final sample = CurrencyFmt.format(context, 0);
    final parts = sample.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
    bool dense = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: dense,
      contentPadding: dense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon, size: 20),
      prefixText: prefixText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < AppSizes.mobileBreakpoint;
    final symbol = _currencySymbol(context);
    final amountHint = _moneyHint(context);

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
          return SafeArea(
            child: SingleChildScrollView(
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
                      Text('Supplier & Status',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSizes.padding),

                      _buildSupplierSelector(),

                      const SizedBox(height: AppSizes.padding),
                      LayoutBuilder(
                        builder: (ctx, c) {
                          final vertical = c.maxWidth < 560; // make this a bit wider to avoid cramped fields
                          if (vertical) {
                            return Column(
                              children: [
                                _buildStatusDropdown(),
                                const SizedBox(height: AppSizes.smallPadding),
                                _buildPaidAmount(symbol, amountHint),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: _buildStatusDropdown()),
                              const SizedBox(width: AppSizes.smallPadding),
                              Expanded(child: _buildPaidAmount(symbol, amountHint)),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppSizes.padding),
                      _buildNotes(),

                      const SizedBox(height: AppSizes.padding * 1.5),
                      Text('Line Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSizes.smallPadding),

                      ..._lines.asMap().entries.map((e) => _buildLineItemResponsive(e.key, e.value, symbol, amountHint)),

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
                      _buildItemsPreview(),

                      const SizedBox(height: AppSizes.padding),
                      _buildTotals(),
                      const SizedBox(height: AppSizes.padding * 1.5),

                      LayoutBuilder(
                        builder: (ctx, c) {
                          final vertical = c.maxWidth < 420;
                          if (vertical) {
                            return Column(
                              children: [
                                OutlinedButton(
                                  onPressed: _submitting ? null : widget.onCancel,
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(height: AppSizes.smallPadding),
                                ElevatedButton.icon(
                                  onPressed: _submitting ? null : _submit,
                                  icon: const Icon(Icons.save),
                                  label: Text(_submitting ? 'Saving...' : 'Save Purchase'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.kPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Row(
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
                          );
                        },
                      ),
                    ],
                  ),
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
                decoration: _inputDecoration(label: 'Search supplier', icon: Icons.search),
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
      value: _status,
      items: const [
        DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
        DropdownMenuItem(value: 'paid', child: Text('Paid')),
        DropdownMenuItem(value: 'credited', child: Text('Credited')),
      ],
      decoration: _inputDecoration(label: 'Status', icon: Icons.assignment_turned_in_outlined),
      onChanged: (v) => setState(() => _status = v ?? 'unpaid'),
    );
  }

  Widget _buildPaidAmount(String symbol, String amountHint) {
    return TextFormField(
      controller: _paidAmountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _moneyInputFormatters(context),
      decoration: _inputDecoration(
        label: 'Paid Amount (optional)',
        icon: Icons.payments_outlined,
        hint: amountHint,
        prefixText: symbol.isNotEmpty ? '$symbol ' : null,
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
      decoration: _inputDecoration(label: 'Notes (optional)', icon: Icons.sticky_note_2_outlined),
    );
  }

  // Line item row - mobile-first, prevents overflow on small widths
  Widget _buildLineItemResponsive(int index, _LineItemVM vm, String symbol, String amountHint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smallPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560; // widen breakpoint to reduce cramped UI
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductDropdown(vm),
                const SizedBox(height: AppSizes.smallPadding),
                Row(
                  children: [
                    Expanded(child: _qtyField(vm, dense: true)),
                    const SizedBox(width: AppSizes.smallPadding),
                    Expanded(child: _priceField(vm, symbol, amountHint, dense: true)),
                    const SizedBox(width: AppSizes.smallPadding),
                    SizedBox(
                      width: 40,
                      child: _removeBtn(index),
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildProductDropdown(vm)),
              const SizedBox(width: AppSizes.smallPadding),
              Expanded(flex: 2, child: _qtyField(vm, dense: true)),
              const SizedBox(width: AppSizes.smallPadding),
              Expanded(flex: 3, child: _priceField(vm, symbol, amountHint, dense: true)),
              const SizedBox(width: AppSizes.smallPadding),
              SizedBox(
                width: 44,
                child: _removeBtn(index),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _qtyField(_LineItemVM vm, {bool dense = false}) {
    return TextFormField(
      controller: vm.qtyCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _inputDecoration(label: 'Qty', icon: Icons.format_list_numbered, hint: '0', dense: dense),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n <= 0) return 'Qty';
        return null;
      },
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.next,
      textAlign: TextAlign.center,
    );
  }

  Widget _priceField(_LineItemVM vm, String symbol, String amountHint, {bool dense = false}) {
    return TextFormField(
      controller: vm.priceCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _moneyInputFormatters(context),
      decoration: _inputDecoration(
        label: 'Unit Price',
        icon: Icons.attach_money,
        hint: amountHint,
        prefixText: symbol.isNotEmpty ? '$symbol ' : null,
        dense: dense,
      ),
      validator: (v) {
        final d = double.tryParse(v ?? '');
        if (d == null || d <= 0) return 'Price';
        return null;
      },
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.next,
      textAlign: TextAlign.center,
    );
  }

  Widget _removeBtn(int index) {
    return IconButton(
      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
      onPressed: () => _removeLine(index),
      tooltip: 'Remove',
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildProductDropdown(_LineItemVM vm) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, pState) {
        if (pState is ProductsLoading) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (pState is ProductsLoaded) {
          return DropdownButtonFormField<Product>(
            value: vm.product,
            isExpanded: true,
            items: pState.products
                .map((p) => DropdownMenuItem<Product>(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            decoration: _inputDecoration(label: 'Product', icon: Icons.inventory_2_outlined),
            onChanged: (val) => setState(() => vm.product = val),
            validator: (val) => val == null ? 'Product' : null,
          );
        }
        return const Text('Products not loaded');
      },
    );
  }

  Widget _buildItemsPreview() {
    final items = _validPreviewLines();
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text('No valid items yet. Add product, quantity and price.',
                style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Purchased Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSizes.smallPadding),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
          itemBuilder: (_, i) {
            final l = items[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey.withValues(alpha: 0.10),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.blueGrey),
              ),
              title: Text(l.product?.name ?? '-', overflow: TextOverflow.ellipsis),
              subtitle: Text('Qty: ${l.qty}  •  Unit: ${CurrencyFmt.format(context, l.price)}'),
              trailing: Text(
                CurrencyFmt.format(context, l.lineTotal),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTotals() {
    final subtotal = _computeSubtotal();
    return Row(
      children: [
        Expanded(
          child: Text(
            'Subtotal: ${CurrencyFmt.format(context, subtotal)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}