import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_event.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';
import 'package:sales_app/utils/platform_helper.dart';
import 'package:sales_app/utils/responsive.dart';
import 'package:sales_app/utils/currency.dart';
import 'package:sales_app/widgets/barcode_scanner_screen.dart';

import 'package:sales_app/features/products/presentation/unit_overlay_screen.dart';
import 'package:sales_app/features/products/presentation/category_overlay_screen.dart';

// Settings for currency-aware inputs
import 'package:sales_app/features/settings/bloc/settings_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_state.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';

enum ProductOverlayMode { create, view, edit, deleteConfirm }

class ProductOverlayScreen extends StatefulWidget {
  final Product? product;
  final ProductOverlayMode mode;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const ProductOverlayScreen({
    super.key,
    required this.product,
    required this.mode,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<ProductOverlayScreen> createState() => _ProductOverlayScreenState();
}

class _ProductOverlayScreenState extends State<ProductOverlayScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _initialQuantityController = TextEditingController(text: '0');
  final _pricePerQuantityController = TextEditingController(text: '0');
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _locationController = TextEditingController();
  final _reorderLevelController = TextEditingController(text: '0');

  String? _selectedSupplierName;
  int? _selectedUnitId;
  int? _selectedCategoryId;

  List<UnitOption> _units = [];
  List<CategoryOption> _categories = [];
  List<SupplierOption> _suppliers = [];

  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    if (widget.product != null && widget.mode != ProductOverlayMode.create) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _initialQuantityController.text = p.initialQuantity.toString();
      _pricePerQuantityController.text = p.pricePerQuantity.toString();
      _priceController.text = p.price?.toString() ?? '';
      _barcodeController.text = p.barcode ?? '';
      _locationController.text = p.location ?? '';
      _reorderLevelController.text = p.reorderLevel.toString();
      _selectedUnitId = p.unitId;
      _selectedCategoryId = p.categoryId;
      _selectedSupplierName = p.supplier;
    }
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final service = context.read<ProductService>();
      final results = await Future.wait([
        service.getUnits(),
        service.getCategories(),
        service.getSuppliers(),
      ]);
      if (!mounted) return;

      final rawSuppliers = results[2] as List<SupplierOption>;
      final dedupedSuppliers = <String, SupplierOption>{for (final s in rawSuppliers) s.name: s};

      setState(() {
        _units = results[0] as List<UnitOption>;
        _categories = results[1] as List<CategoryOption>;
        _suppliers = dedupedSuppliers.values.toList();
        _loadingMeta = false;

        if (widget.product != null && widget.mode != ProductOverlayMode.create) {
          if (_selectedUnitId == null && widget.product!.unitName != null) {
            final match = _units.where((u) => u.name.toLowerCase() == widget.product!.unitName!.toLowerCase());
            if (match.isNotEmpty) _selectedUnitId = match.first.id;
          }
          if (_selectedCategoryId == null && widget.product!.categoryName != null) {
            final match = _categories.where((c) => c.name.toLowerCase() == widget.product!.categoryName!.toLowerCase());
            if (match.isNotEmpty) _selectedCategoryId = match.first.id;
          }
        }

        if (_selectedUnitId != null && !_units.any((u) => u.id == _selectedUnitId)) _selectedUnitId = null;
        if (_selectedCategoryId != null && !_categories.any((c) => c.id == _selectedCategoryId)) _selectedCategoryId = null;
        if (_selectedSupplierName != null && !_suppliers.any((s) => s.name == _selectedSupplierName)) {
          _selectedSupplierName = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMeta = false);
      _snack('Failed to load data: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _initialQuantityController.dispose();
    _pricePerQuantityController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _locationController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  void _close() => widget.onCancel?.call();

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() => _barcodeController.text = code);
      HapticFeedback.mediumImpact();
      _snack('Barcode scanned');
    }
  }

  Future<void> _openUnitCreate() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: UnitOverlayScreen(
            unit: null,
            mode: UnitOverlayMode.create,
            onSaved: () async {
              Navigator.of(context).pop();
              await _loadMeta();
              _snack('Unit created');
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _openCategoryCreate() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: CategoryOverlayScreen(
            category: null,
            mode: CategoryOverlayMode.create,
            onSaved: () async {
              Navigator.of(context).pop();
              await _loadMeta();
              _snack('Category created');
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  // Currency helpers for inputs and formatting
  int _fractionDigits(BuildContext context) {
    final st = context.read<SettingsBloc>().state;
    if (st is SettingsLoaded) return st.settings.fractionDigits;
    if (st is SettingsSaved) return st.settings.fractionDigits;
    return AppSettings.fallback.fractionDigits;
  }

  String _currencySymbol(BuildContext context) {
    final sample = CurrencyFmt.format(context, 0);
    final parts = sample.split(' ');
    return parts.isNotEmpty ? parts.first : '';
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

  InputDecoration _decor({
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: cs.primary),
      prefixText: prefixText,
      border: const OutlineInputBorder(),
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
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _close,
            tooltip: 'Close',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _loadingMeta
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : SingleChildScrollView(
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _close,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForMode(ProductOverlayMode mode) {
    switch (mode) {
      case ProductOverlayMode.create:
        return 'Add Product';
      case ProductOverlayMode.view:
        return 'Product Details';
      case ProductOverlayMode.edit:
        return 'Edit Product';
      case ProductOverlayMode.deleteConfirm:
        return 'Delete Product';
    }
  }

  Widget _buildContent() {
    switch (widget.mode) {
      case ProductOverlayMode.create:
        return _buildCreateOrEdit(isCreate: true);
      case ProductOverlayMode.view:
        return _buildViewMobileFirst();
      case ProductOverlayMode.edit:
        return _buildCreateOrEdit(isCreate: false);
      case ProductOverlayMode.deleteConfirm:
        return _buildDeleteConfirm();
    }
  }

  // Mobile-first Product Details
  Widget _buildViewMobileFirst() {
    final p = widget.product!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDesktop = Responsive.isDesktop(context);

    final totalValue = p.totalValue ?? (p.quantity * p.pricePerQuantity);
    final created = p.createdAt != null ? DateFormat.yMMMd().format(p.createdAt) : '—';
    final updated = p.updatedAt != null ? DateFormat.yMMMd().format(p.updatedAt) : '—';

    final kpiCards = <_Kpi>[
      _Kpi(label: 'Quantity', value: p.unitName != null && p.unitName!.isNotEmpty ? '${p.quantity.toStringAsFixed(2)} ${p.unitName!.toUpperCase()}' : p.quantity.toStringAsFixed(2), icon: Icons.inventory_2_outlined),
      _Kpi(label: 'Total Value', value: CurrencyFmt.format(context, totalValue), icon: Icons.stacked_bar_chart),
      _Kpi(label: 'Price/Qty', value: CurrencyFmt.format(context, p.pricePerQuantity), icon: Icons.price_change_outlined),
      _Kpi(label: 'Selling Price', value: p.price != null ? CurrencyFmt.format(context, p.price!) : 'N/A', icon: Icons.attach_money),
    ];

    final details = <_Detail>[
      _Detail('Initial Quantity', p.initialQuantity.toStringAsFixed(2)),
      _Detail('Barcode', p.barcode ?? 'N/A', copyable: p.barcode != null && p.barcode!.isNotEmpty),
      _Detail('Category', (p.categoryName ?? 'N/A').toUpperCase()),
      _Detail('Location', p.location ?? 'N/A'),
      _Detail('Reorder Level', p.reorderLevel.toStringAsFixed(2)),
      _Detail('Supplier', p.supplier ?? 'N/A'),
      _Detail('Created At', created),
      _Detail('Updated At', updated),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          name: p.name,
          icon: Icons.inventory_2,
          color: cs.primary,
          subtitle: p.description?.isNotEmpty == true ? p.description! : null,
        ),
        const SizedBox(height: AppSizes.padding),

        // Chips row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (p.unitName != null && p.unitName!.isNotEmpty) _TagChip(label: p.unitName!),
            if (p.categoryName != null && p.categoryName!.isNotEmpty) _TagChip(label: p.categoryName!.toUpperCase()),
            if (p.supplier != null && p.supplier!.isNotEmpty) _TagChip(label: p.supplier!),
          ],
        ),
        const SizedBox(height: AppSizes.largePadding),

        // KPI cards
        _KpiGrid(items: kpiCards),

        const SizedBox(height: AppSizes.largePadding),

        // Other details grid
        _DetailsGrid(items: details),

        if (isDesktop) const SizedBox(height: AppSizes.largePadding),
      ],
    );
  }

  // CREATE/EDIT
  Widget _buildCreateOrEdit({required bool isCreate}) {
    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final symbol = _currencySymbol(context);
    final moneyHint = _moneyHint(context);

    Widget unitPicker() => Row(
          children: [
            Expanded(child: _unitDropdown()),
            const SizedBox(width: 8),
            Tooltip(message: 'Add Unit', child: IconButton(icon: Icon(Icons.add_circle_outline, color: cs.primary), onPressed: _openUnitCreate)),
          ],
        );

    Widget categoryPicker() => Row(
          children: [
            Expanded(child: _categoryDropdown()),
            const SizedBox(width: 8),
            Tooltip(message: 'Add Category', child: IconButton(icon: Icon(Icons.add_circle_outline, color: cs.primary), onPressed: _openCategoryCreate)),
          ],
        );

    // Money fields (currency-aware)
    Widget sellingPriceField() => TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _moneyInputFormatters(context),
          validator: _numberValidator,
          decoration: _decor(label: 'Selling Price*', icon: Icons.attach_money, hint: moneyHint, prefixText: symbol.isNotEmpty ? '$symbol ' : null),
          onTap: () => HapticFeedback.lightImpact(),
        );

    Widget pricePerQtyField() => TextFormField(
          controller: _pricePerQuantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _moneyInputFormatters(context),
          validator: _numberValidator,
          decoration: _decor(label: 'Price per Quantity*', icon: Icons.price_change, hint: moneyHint, prefixText: symbol.isNotEmpty ? '$symbol ' : null),
          onTap: () => HapticFeedback.lightImpact(),
        );

    Widget leftCol() => Column(children: [
          _inputRequired(controller: _nameController, label: 'Product Name*', icon: Icons.label_outline, validator: _requiredValidator),
          const SizedBox(height: AppSizes.padding),
          _inputRequired(controller: _initialQuantityController, label: 'Initial Quantity*', icon: Icons.production_quantity_limits, keyboardType: TextInputType.number, validator: _numberValidator),
          const SizedBox(height: AppSizes.padding),
          sellingPriceField(),
          const SizedBox(height: AppSizes.padding),
          _barcodeField(),
          const SizedBox(height: AppSizes.padding),
          unitPicker(),
          const SizedBox(height: AppSizes.padding),
          _supplierDropdownRow(),
        ]);

    Widget rightCol() => Column(children: [
          pricePerQtyField(),
          const SizedBox(height: AppSizes.padding),
          categoryPicker(),
          const SizedBox(height: AppSizes.padding),
          _input(controller: _locationController, label: 'Location', icon: Icons.location_on_outlined),
          const SizedBox(height: AppSizes.padding),
          _inputRequired(controller: _reorderLevelController, label: 'Reorder Level*', icon: Icons.warning_amber_outlined, keyboardType: TextInputType.number, validator: _numberValidator),
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isCreate ? 'Add Product' : 'Edit ${widget.product?.name ?? ""}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.padding),
        _input(controller: _descriptionController, label: 'Description', icon: Icons.description_outlined, maxLines: 3),
        const SizedBox(height: AppSizes.largePadding),
        Form(
          key: _formKey,
          child: isDesktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: leftCol()),
                  const SizedBox(width: AppSizes.padding),
                  Expanded(child: rightCol()),
                ])
              : Column(
                  children: [
                    leftCol(),
                    const SizedBox(height: AppSizes.padding),
                    pricePerQtyField(),
                    const SizedBox(height: AppSizes.padding),
                    _categoryDropdown(),
                    const SizedBox(height: AppSizes.padding),
                    _input(controller: _locationController, label: 'Location', icon: Icons.location_on_outlined),
                    const SizedBox(height: AppSizes.padding),
                    _inputRequired(controller: _reorderLevelController, label: 'Reorder Level*', icon: Icons.warning_amber_outlined, keyboardType: TextInputType.number, validator: _numberValidator),
                  ],
                ),
        ),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel'))),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isCreate ? _submitCreate : _submitEdit,
                icon: Icon(isCreate ? Icons.add : Icons.save),
                label: Text(isCreate ? 'Create' : 'Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // DELETE CONFIRM
  Widget _buildDeleteConfirm() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = widget.product?.name ?? 'this product';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 8),
          Expanded(child: Text('Delete $name', style: theme.textTheme.titleLarge?.copyWith(color: cs.error, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: AppSizes.padding),
        Text('Are you sure you want to delete this product? This action cannot be undone.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel'))),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    context.read<ProductsBloc>().add(DeleteProductEvent(widget.product!.id));
    _snack('Deleting product...');
    widget.onSaved?.call();
  }

  // Inputs and helpers
  InputDecoration _inputDecoration(String label) => InputDecoration(labelText: label);

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: cs.primary), border: const OutlineInputBorder()),
    );
  }

  Widget _inputRequired({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: cs.primary), border: const OutlineInputBorder()),
      onTap: () => HapticFeedback.lightImpact(),
      inputFormatters: keyboardType == TextInputType.number ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field cannot be empty';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a valid number';
    if (double.tryParse(value) == null) return 'Please enter a valid number';
    return null;
  }

  String _formatCategoryName(String category) {
    return category.split('_').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  // Dropdowns
  int? get _unitValue => _units.any((u) => u.id == _selectedUnitId) ? _selectedUnitId : null;
  int? get _categoryValue => _categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null;
  String? get _supplierValue => _suppliers.any((s) => s.name == _selectedSupplierName) ? _selectedSupplierName : null;

  Widget _unitDropdown() {
    return DropdownButtonFormField<int>(
      value: _unitValue,
      isExpanded: true,
      items: _units.map((u) => DropdownMenuItem<int>(value: u.id, child: Text(u.name))).toList(),
      onChanged: (v) => setState(() => _selectedUnitId = v),
      decoration: _inputDecoration('Unit'),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _categoryValue,
      isExpanded: true,
      items: _categories.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(_formatCategoryName(c.name)))).toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      decoration: _inputDecoration('Category'),
    );
  }

  Widget _supplierDropdown() {
    return DropdownButtonFormField<String>(
      value: _supplierValue,
      isExpanded: true,
      items: _suppliers.map((s) => DropdownMenuItem<String>(value: s.name, child: Text(s.name))).toList(),
      onChanged: (v) => setState(() => _selectedSupplierName = v),
      decoration: _inputDecoration('Supplier'),
    );
  }

  Widget _supplierDropdownRow() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: _supplierDropdown()),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Clear Supplier',
          child: IconButton(
            icon: Icon(Icons.clear, color: cs.error),
            onPressed: () => setState(() => _selectedSupplierName = null),
          ),
        ),
      ],
    );
  }

  Widget _barcodeField() {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _barcodeController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Barcode',
        prefixIcon: Icon(Icons.qr_code, color: cs.primary),
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_barcodeController.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _barcodeController.clear()),
              ),
            if (PlatformHelper.isMobile)
              IconButton(
                tooltip: 'Scan',
                icon: const Icon(Icons.qr_code_scanner_outlined),
                onPressed: _scanBarcode,
              ),
          ],
        ),
      ),
      onTap: () => HapticFeedback.lightImpact(),
    );
  }

  // Actions
  Future<void> _submitCreate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'initial_quantity': _initialQuantityController.text.trim(),
      'quantity': _initialQuantityController.text.trim(),
      'price_per_quantity': _pricePerQuantityController.text.trim(),
      'price': _priceController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'unit_id': _selectedUnitId,
      'category_id': _selectedCategoryId,
      'location': _locationController.text.trim(),
      'reorder_level': _reorderLevelController.text.trim(),
      'supplier': _selectedSupplierName,
    };

    context.read<ProductsBloc>().add(AddProduct(data));
    _snack('Creating product...');
    widget.onSaved?.call();
  }

  Future<void> _submitEdit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final product = widget.product!;
    final Map<String, dynamic> updated = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'initial_quantity': _initialQuantityController.text.trim(),
      'price_per_quantity': _pricePerQuantityController.text.trim(),
      'price': _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'unit_id': _selectedUnitId,
      'category_id': _selectedCategoryId,
      'location': _locationController.text.trim(),
      'reorder_level': _reorderLevelController.text.trim(),
      'supplier': _selectedSupplierName,
    };

    context.read<ProductsBloc>().add(UpdateProductEvent(product.id, updated));
    _snack('Saving changes...');
    widget.onSaved?.call();
  }
}

// UI helpers

class _HeaderCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _HeaderCard({
    required this.name,
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
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ),
              ],
            ),
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
      side: BorderSide(color: cs.primary.withValues(alpha: (0.4))),
      backgroundColor: cs.primary.withValues(alpha: .08),
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