import 'package:flutter/material.dart';
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

  // Supplier name for View mode (ensure we show name, not id)
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
      // Reuse ProductService suppliers endpoint
      final ps = context.read<ProductService>();
      // Use the in-memory results if already loaded during add flow, else fetch
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
      SnackBar(content: Text(msg), backgroundColor: color ?? AppColors.kPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < AppSizes.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kPrimary,
        foregroundColor: AppColors.kTextOnPrimary,
        elevation: 0,
        title: Text(_titleForMode(widget.mode)),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: _close, tooltip: 'Close'),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 2),
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
          child: _buildContent(),
        ),
      ),
    );
  }

  String _titleForMode(StockOverlayMode mode) {
    switch (mode) {
      case StockOverlayMode.view:
        return 'Stock Transaction Details';
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
        return _buildTxnView();
      case StockOverlayMode.addStock:
        return _buildAddStock();
      case StockOverlayMode.edit:
        return _buildTxnEdit();
      case StockOverlayMode.deleteConfirm:
        return _buildTxnDeleteConfirm();
    }
  }

  // VIEW TRANSACTION
  Widget _buildTxnView() {
    final t = widget.transaction!;
    final isDesktop = Responsive.isDesktop(context);

    Widget field(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.kTextSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    final supplierText = () {
      if (_loadingViewSupplierName) return 'Loading supplier...';
      final name = _viewSupplierName ?? t.supplierName;
      return name ?? 'N/A';
    }();

    final fields = [
      field('Product', (t.productName ?? 'Product #${t.productId}')),
      field('Supplier', supplierText),
      field('Amount Added', t.amountAdded.toStringAsFixed(2)),
      field('Price per Unit', _money.format(t.pricePerUnit)),
      field('Total Cost', _money.format(t.totalCost)),
      field('Unit', t.unitName ?? 'N/A'),
      field('User ID', t.userId.toString()),
      field('Date', DateFormat.yMMMd().add_jm().format(t.date)),
      field('Transaction ID', '#${t.id}'),
    ];

    Widget details() {
      if (isDesktop) {
        final split = (fields.length / 2).ceil();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: fields.sublist(0, split))),
            const SizedBox(width: AppSizes.largePadding),
            Expanded(child: Column(children: fields.sublist(split))),
          ],
        );
      }
      return Column(children: fields);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.kPrimary.withValues(alpha: 0.1),
              child:  Icon(Icons.receipt_long, color: AppColors.kPrimary),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: Text(
                'Txn #${t.id}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.largePadding),
        details(),
        const SizedBox(height: AppSizes.largePadding),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: widget.onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              foregroundColor: AppColors.kTextOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  // ADD STOCK
  Widget _buildAddStock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add Stock',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.largePadding),

        // Product selector
        if (_selectedProduct != null)
          _SelectedProductTile(
            product: _selectedProduct!,
            onClear: widget.product == null
                ? () {
                    setState(() => _selectedProduct = null);
                  }
                : null,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomInput(
                controller: _productSearchController,
                label: 'Search Product',
                prefixIcon: Icons.search,
              ),
              const SizedBox(height: AppSizes.smallPadding),
              SizedBox(
                height: 200,
                child: _loadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : _buildProductResults(),
              ),
              const SizedBox(height: AppSizes.padding),
            ],
          ),

        // Supplier selector
        Text('Supplier', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.smallPadding),
        if (_selectedSupplier != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.kPrimary.withValues(alpha: 0.08),
              child:  Icon(Icons.local_shipping, color: AppColors.kPrimary),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomInput(
                controller: _supplierSearchController,
                label: 'Search Supplier',
                prefixIcon: Icons.search,
              ),
              const SizedBox(height: AppSizes.smallPadding),
              SizedBox(
                height: 180,
                child: _loadingSuppliers
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSupplierResults(),
              ),
            ],
          ),
        const SizedBox(height: AppSizes.padding),

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
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextSecondary,
                  side: const BorderSide(color: AppColors.kDivider),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitAddStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  foregroundColor: AppColors.kTextOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
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
          title: Text(p.name, overflow: TextOverflow.ellipsis),
          subtitle: Text('ID: ${p.id} • In stock: ${p.quantity.toStringAsFixed(2)}'),
          leading: const Icon(Icons.inventory_2),
          onTap: () {
            setState(() => _selectedProduct = p);
          },
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
          title: Text(s.name, overflow: TextOverflow.ellipsis),
          subtitle: Text('ID: ${s.id}'),
          leading: const Icon(Icons.local_shipping),
          onTap: () {
            setState(() => _selectedSupplier = s);
          },
        );
      },
    );
  }

  void _submitAddStock() {
    if (_selectedProduct == null) {
      _snack('Please select a product first.', color: AppColors.kError);
      return;
    }
    if (!(_addFormKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _snack('User is not authenticated.', color: AppColors.kError);
      return;
    }

    // Dispatch with product & supplier so it shows instantly and links on backend
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

  // EDIT TRANSACTION
  Widget _buildTxnEdit() {
    final t = widget.transaction!;
    final isDesktop = Responsive.isDesktop(context);

    Widget twoCol() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                CustomInput(
                  controller: _editAmountController,
                  label: 'Amount Added',
                  prefixIcon: Icons.add,
                  keyboardType: TextInputType.number,
                  validator: (v) => _positiveValidator(v, 'Amount'),
                ),
              ]),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: Column(children: [
                CustomInput(
                  controller: _editPricePerUnitController,
                  label: 'Price per Unit',
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _positiveValidator(v, 'Price per unit'),
                ),
              ]),
            ),
          ],
        );

    Widget oneCol() => Column(children: [
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
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Edit Txn #${t.id}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.largePadding),
        Form(key: _editTxnFormKey, child: isDesktop ? twoCol() : oneCol()),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextSecondary,
                  side: const BorderSide(color: AppColors.kDivider),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitTxnEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  foregroundColor: AppColors.kTextOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
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

  // DELETE TRANSACTION
  Widget _buildTxnDeleteConfirm() {
    final t = widget.transaction!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.kError),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delete Txn #${t.id}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.kError, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        const SizedBox(height: AppSizes.padding),
        Text(
          'Are you sure you want to delete this stock transaction? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextSecondary,
                  side: const BorderSide(color: AppColors.kDivider),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _confirmTxnDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kError,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.smallPadding),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmTxnDelete() {
    context.read<StockBloc>().add(DeleteStockTransactionEvent(widget.transaction!.id));
    widget.onSaved?.call();
  }
}

class _SelectedProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onClear;
  const _SelectedProductTile({required this.product, this.onClear});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.kPrimary.withValues(alpha: 0.1),
        child: Icon(Icons.inventory_2, color: AppColors.kPrimary),
      ),
      title: Text(product.name, overflow: TextOverflow.ellipsis),
      subtitle: Text('ID: ${product.id} • In stock: ${product.quantity.toStringAsFixed(2)}'),
      trailing: onClear != null ? IconButton(icon: const Icon(Icons.close), onPressed: onClear) : null,
    );
  }
}