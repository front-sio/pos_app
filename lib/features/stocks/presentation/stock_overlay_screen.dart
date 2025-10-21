import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';
import 'package:sales_app/features/stocks/bloc/stock_bloc.dart';
import 'package:sales_app/features/stocks/bloc/stock_event.dart';
import 'package:sales_app/features/stocks/data/stock_transaction_model.dart';
import 'package:sales_app/utils/responsive.dart';
import 'package:sales_app/widgets/custom_field.dart';

enum StockOverlayMode { view, addStock, edit, deleteConfirm }

class StockOverlayScreen extends StatefulWidget {
  // For addStock mode, product can be null to allow selection inside overlay.
  final Product? product;
  // For view/edit/delete modes
  final StockTransaction? transaction;

  final StockOverlayMode mode;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const StockOverlayScreen({
    super.key,
    required this.mode,
    this.product,
    this.transaction,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<StockOverlayScreen> createState() => _StockOverlayScreenState();
}

class _StockOverlayScreenState extends State<StockOverlayScreen> {
  // Add Stock controllers
  final _addAmountController = TextEditingController();
  final _addPricePerUnitController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();

  // Product selector for Add Stock
  final _productSearchController = TextEditingController();
  List<Product> _productResults = [];
  Product? _selectedProduct;
  bool _loadingProducts = false;

  // Supplier selector (for Add Stock)
  final _supplierSearchController = TextEditingController();
  List<SupplierOption> _supplierResults = [];
  SupplierOption? _selectedSupplier;
  bool _loadingSuppliers = false;

  // Supplier name for View mode
  String? _viewSupplierName;
  bool _loadingViewSupplierName = false;

  // Edit Transaction controllers
  final _editTxnFormKey = GlobalKey<FormState>();
  final _editAmountController = TextEditingController();
  final _editPricePerUnitController = TextEditingController();

  final NumberFormat _money = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    if (widget.mode == StockOverlayMode.edit && widget.transaction != null) {
      _editAmountController.text = widget.transaction!.amountAdded.toString();
      _editPricePerUnitController.text = widget.transaction!.pricePerUnit.toString();
    }

    if (widget.mode == StockOverlayMode.addStock) {
      _selectedProduct = widget.product;
      _loadInitialProducts();
      _loadSuppliers();
      _productSearchController.addListener(_onProductSearchChanged);
      _supplierSearchController.addListener(_onSupplierSearchChanged);
    }

    if (widget.mode == StockOverlayMode.view && widget.transaction != null) {
      _ensureSupplierNameForView(widget.transaction!);
    }
  }

  @override
  void dispose() {
    _addAmountController.dispose();
    _addPricePerUnitController.dispose();
    _editAmountController.dispose();
    _editPricePerUnitController.dispose();
    _productSearchController
      ..removeListener(_onProductSearchChanged)
      ..dispose();
    _supplierSearchController
      ..removeListener(_onSupplierSearchChanged)
      ..dispose();
    super.dispose();
  }

  // Ensure we display supplier name (never the id) in view mode
  Future<void> _ensureSupplierNameForView(StockTransaction t) async {
    if (t.supplierName != null && t.supplierName!.trim().isNotEmpty) {
      setState(() => _viewSupplierName = t.supplierName);
      return;
    }
    if (t.supplierId == null) {
      setState(() => _viewSupplierName = null);
      return;
    }
    setState(() => _loadingViewSupplierName = true);
    try {
      final ps = context.read<ProductService>();
      if (_supplierResults.isEmpty) {
        final list = await ps.getSuppliers();
        _supplierResults = list;
      }
      final match = _supplierResults.firstWhere(
        (s) => s.id == t.supplierId,
        orElse: () => SupplierOption(id: t.supplierId!, name: ''),
      );
      setState(() => _viewSupplierName = (match.name.isNotEmpty ? match.name : null));
    } catch (_) {
      // Keep null; UI will show N/A
    } finally {
      if (mounted) setState(() => _loadingViewSupplierName = false);
    }
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final productService = context.read<ProductService>();
      final list = await productService.getProducts(page: 1, limit: 50);
      setState(() {
        _productResults = list;
      });
    } catch (_) {
      // ignore error; allow retry
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loadingSuppliers = true);
    try {
      final productService = context.read<ProductService>();
      final list = await productService.getSuppliers();
      setState(() {
        _supplierResults = list;
      });
    } catch (_) {
      // ignore error; allow retry
    } finally {
      if (mounted) setState(() => _loadingSuppliers = false);
    }
  }

  void _onProductSearchChanged() => setState(() {});
  void _onSupplierSearchChanged() => setState(() {});

  void _close() => widget.onCancel?.call();

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color ?? AppColors.kPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSmall = MediaQuery.of(context).size.width < AppSizes.mobileBreakpoint;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: Text(_titleForMode(widget.mode)),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: _close, tooltip: 'Close'),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 2),
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 1.5),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(color: cs.outlineVariant, width: 1.2),
              boxShadow: [
                if (theme.brightness == Brightness.light)
                  const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: _buildContent(),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: _buildBottomBar(),
      ),
    );
  }

  String _titleForMode(StockOverlayMode mode) {
    switch (mode) {
      case StockOverlayMode.view:
        return 'Stock Transaction';
      case StockOverlayMode.addStock:
        return 'Add Stock';
      case StockOverlayMode.edit:
        return 'Edit Stock Transaction';
      case StockOverlayMode.deleteConfirm:
        return 'Delete Stock Transaction';
    }
  }

  Widget _buildContent() {
    switch (widget.mode) {
      case StockOverlayMode.view:
        return _buildTxnViewMobileFirst();
      case StockOverlayMode.addStock:
        return _buildAddStockMobileFirst();
      case StockOverlayMode.edit:
        return _buildTxnEditMobileFirst();
      case StockOverlayMode.deleteConfirm:
        return _buildTxnDeleteConfirmMobileFirst();
    }
  }

  // ---------------- VIEW (Mobile-first, responsive) ----------------
  Widget _buildTxnViewMobileFirst() {
    final t = widget.transaction!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final createdAt = DateFormat.yMMMd().add_jm().format(t.date);
    final supplierText = _loadingViewSupplierName
        ? 'Loading...'
        : (_viewSupplierName ?? t.supplierName ?? 'N/A');

    final kpis = <_Kpi>[
      _Kpi(label: 'Quantity Added', value: t.amountAdded.toStringAsFixed(2), icon: Icons.add_chart),
      _Kpi(label: 'Price/Unit', value: _money.format(t.pricePerUnit), icon: Icons.price_change_outlined),
      _Kpi(label: 'Total Cost', value: _money.format(t.totalCost), icon: Icons.account_balance_wallet_outlined),
      _Kpi(label: 'Date', value: createdAt, icon: Icons.event),
    ];

    final details = <_Detail>[
      _Detail('Transaction ID', '#${t.id}', copyable: true),
      _Detail('Product', t.productName ?? 'Product #${t.productId}'),
      _Detail('Unit', t.unitName ?? 'N/A'),
      _Detail('Supplier', supplierText),
      _Detail('User ID', t.userId.toString()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          title: 'Txn #${t.id}',
          subtitle: t.productName ?? 'Product #${t.productId}',
          icon: Icons.receipt_long,
          color: cs.primary,
        ),
        const SizedBox(height: AppSizes.padding),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (t.unitName != null && t.unitName!.isNotEmpty) _TagChip(label: t.unitName!),
            if ((t.productName ?? '').isNotEmpty) _TagChip(label: t.productName!),
            if ((supplierText).isNotEmpty && supplierText != 'N/A') _TagChip(label: supplierText),
          ],
        ),

        const SizedBox(height: AppSizes.largePadding),
        _KpiGrid(items: kpis),

        const SizedBox(height: AppSizes.largePadding),
        _DetailsGrid(items: details),
      ],
    );
  }

  // ---------------- ADD STOCK (Mobile-first) ----------------
  Widget _buildAddStockMobileFirst() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget productSelector() {
      final hasSelection = _selectedProduct != null;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: hasSelection
            ? _SelectedTile(
                leadingIcon: Icons.inventory_2,
                color: cs.primary,
                title: _selectedProduct!.name,
                subtitle: 'ID: ${_selectedProduct!.id} • In stock: ${_selectedProduct!.quantity.toStringAsFixed(2)}',
                onClear: widget.product == null ? () => setState(() => _selectedProduct = null) : null,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomInput(
                    controller: _productSearchController,
                    label: 'Search Product',
                    prefixIcon: Icons.search,
                  ),
                  const SizedBox(height: AppSizes.smallPadding),
                  SizedBox(
                    height: 220,
                    child: _loadingProducts
                        ? const Center(child: CircularProgressIndicator())
                        : _buildProductResults(),
                  ),
                ],
              ),
      );
    }

    Widget supplierSelector() {
      final hasSelection = _selectedSupplier != null;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: hasSelection
            ? _SelectedTile(
                leadingIcon: Icons.local_shipping,
                color: cs.primary,
                title: _selectedSupplier!.name,
                subtitle: 'ID: ${_selectedSupplier!.id}',
                onClear: () => setState(() => _selectedSupplier = null),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomInput(
                    controller: _supplierSearchController,
                    label: 'Search Supplier',
                    prefixIcon: Icons.search,
                  ),
                  const SizedBox(height: AppSizes.smallPadding),
                  SizedBox(
                    height: 200,
                    child: _loadingSuppliers
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSupplierResults(),
                  ),
                ],
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          title: 'Add Stock',
          subtitle: _selectedProduct?.name ?? 'Select a product and supplier',
          icon: Icons.add_shopping_cart,
          color: cs.primary,
        ),
        const SizedBox(height: AppSizes.largePadding),

        productSelector(),
        const SizedBox(height: AppSizes.largePadding),

        Text('Supplier', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSizes.smallPadding),
        supplierSelector(),
        const SizedBox(height: AppSizes.largePadding),

        Form(
          key: _addFormKey,
          child: Column(
            children: [
              CustomInput(
                controller: _addAmountController,
                keyboardType: TextInputType.number,
                label: 'Amount to Add',
                prefixIcon: Icons.add_box,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Amount cannot be empty';
                  final v = double.tryParse(value);
                  if (v == null || v <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.padding),
              CustomInput(
                controller: _addPricePerUnitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                label: 'Cost Price per Unit',
                prefixIcon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Cost price cannot be empty';
                  final v = double.tryParse(value);
                  if (v == null || v <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductResults() {
    final q = _productSearchController.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _productResults
        : _productResults.where((p) => p.name.toLowerCase().contains(q)).toList(growable: false);

    if (filtered.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = filtered[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(p.name, overflow: TextOverflow.ellipsis),
          subtitle: Text('ID: ${p.id} • In stock: ${p.quantity.toStringAsFixed(2)}'),
          onTap: () => setState(() => _selectedProduct = p),
        );
      },
    );
  }

  Widget _buildSupplierResults() {
    final q = _supplierSearchController.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _supplierResults
        : _supplierResults.where((s) => s.name.toLowerCase().contains(q)).toList(growable: false);

    if (filtered.isEmpty) {
      return const Center(child: Text('No suppliers found'));
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = filtered[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(s.name, overflow: TextOverflow.ellipsis),
          subtitle: Text('ID: ${s.id}'),
          onTap: () => setState(() => _selectedSupplier = s),
        );
      },
    );
  }

  // ---------------- EDIT TXN (Mobile-first) ----------------
  Widget _buildTxnEditMobileFirst() {
    final t = widget.transaction!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          title: 'Edit Txn #${t.id}',
          subtitle: t.productName ?? 'Product #${t.productId}',
          icon: Icons.edit_note,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSizes.largePadding),

        Form(
          key: _editTxnFormKey,
          child: Column(
            children: [
              CustomInput(
                controller: _editAmountController,
                label: 'Amount Added',
                prefixIcon: Icons.add,
                keyboardType: TextInputType.number,
                validator: (v) => _positiveValidator(v, 'Amount'),
              ),
              const SizedBox(height: AppSizes.padding),
              CustomInput(
                controller: _editPricePerUnitController,
                label: 'Price per Unit',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _positiveValidator(v, 'Price per unit'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _positiveValidator(String? value, String label) {
    if (value == null || value.isEmpty) return '$label cannot be empty';
    final v = double.tryParse(value);
    if (v == null || v <= 0) return 'Enter a valid positive number';
    return null;
  }

  // ---------------- DELETE CONFIRM (Mobile-first) ----------------
  Widget _buildTxnDeleteConfirmMobileFirst() {
    final t = widget.transaction!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          title: 'Delete Txn #${t.id}',
          subtitle: 'This action cannot be undone',
          icon: Icons.warning_amber_rounded,
          color: cs.error,
        ),
        const SizedBox(height: AppSizes.padding),
        Text(
          'Are you sure you want to delete this stock transaction?',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  // ---------------- Bottom action bar (sticky) ----------------
  Widget _buildBottomBar() {
    final cs = Theme.of(context).colorScheme;

    switch (widget.mode) {
      case StockOverlayMode.view:
        return ElevatedButton(
          onPressed: _close,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Close'),
        );

      case StockOverlayMode.addStock:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
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
              child: ElevatedButton(
                onPressed: _submitAddStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        );

      case StockOverlayMode.edit:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
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
              child: ElevatedButton(
                onPressed: _submitTxnEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        );

      case StockOverlayMode.deleteConfirm:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
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
              child: ElevatedButton.icon(
                onPressed: _confirmTxnDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        );
    }
  }

  // ---------------- Actions ----------------
  void _submitAddStock() {
    if (_selectedProduct == null) {
      _snack('Please select a product first.', color: Theme.of(context).colorScheme.error);
      return;
    }
    if (!(_addFormKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _snack('User is not authenticated.', color: Theme.of(context).colorScheme.error);
      return;
    }

    context.read<StockBloc>().add(
          AddStockToProduct(
            productId: _selectedProduct!.id,
            amountAdded: double.parse(_addAmountController.text),
            pricePerUnit: double.parse(_addPricePerUnitController.text),
            userId: authState.userId,
            productName: _selectedProduct!.name,
            supplierId: _selectedSupplier?.id,
          ),
        );
    widget.onSaved?.call();
  }

  void _submitTxnEdit() {
    if (!(_editTxnFormKey.currentState?.validate() ?? false)) return;
    final id = widget.transaction!.id;
    final updated = <String, dynamic>{
      'amount_added': _editAmountController.text.trim(),
      'price_per_unit': _editPricePerUnitController.text.trim(),
    };
    context.read<StockBloc>().add(UpdateStockTransactionEvent(id, updated));
    widget.onSaved?.call();
  }

  void _confirmTxnDelete() {
    context.read<StockBloc>().add(DeleteStockTransactionEvent(widget.transaction!.id));
    widget.onSaved?.call();
  }
}

// ---------------- UI helpers ----------------

class _HeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _HeaderCard({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: cs.primary),
      side: BorderSide(color: cs.primary.withOpacity(0.4)),
      backgroundColor: cs.primary.withOpacity(0.08),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;

  _Kpi({required this.label, required this.value, required this.icon});
}

class _KpiGrid extends StatelessWidget {
  final List<_Kpi> items;
  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w < 420 ? 1 : (w < 680 ? 2 : 4);
      final itemWidth = (w - (cols - 1) * 12) / cols;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items
            .map((e) => SizedBox(
                  width: itemWidth,
                  child: _KpiCard(kpi: e),
                ))
            .toList(),
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(kpi.icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kpi.label, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(kpi.value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail {
  final String label;
  final String value;
  final bool copyable;

  _Detail(this.label, this.value, {this.copyable = false});
}

class _DetailsGrid extends StatelessWidget {
  final List<_Detail> items;
  const _DetailsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w < 420 ? 1 : 2;
      final itemWidth = (w - (cols - 1) * 12) / cols;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items
            .map(
              (d) => SizedBox(
                width: itemWidth,
                child: _DetailCard(detail: d),
              ),
            )
            .toList(),
      );
    });
  }
}

class _DetailCard extends StatelessWidget {
  final _Detail detail;
  const _DetailCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(detail.label, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SelectableText(detail.value, style: theme.textTheme.bodyLarge),
            ]),
          ),
          if (detail.copyable)
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: detail.value));
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied "${detail.value}"'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SelectedTile extends StatelessWidget {
  final IconData leadingIcon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onClear;

  const _SelectedTile({
    required this.leadingIcon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(leadingIcon, color: color),
      ),
      title: Text(title, overflow: TextOverflow.ellipsis),
      subtitle: (subtitle != null && subtitle!.isNotEmpty) ? Text(subtitle!) : null,
      trailing: onClear != null ? IconButton(icon: const Icon(Icons.close), onPressed: onClear) : null,
    );
  }
}