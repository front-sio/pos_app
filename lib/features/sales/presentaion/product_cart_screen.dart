import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';

import 'package:sales_app/features/customers/data/customer_model.dart';
import 'package:sales_app/features/customers/services/customer_services.dart';

import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';

import 'package:sales_app/features/sales/bloc/sales_bloc.dart';
import 'package:sales_app/features/sales/bloc/sales_event.dart';
import 'package:sales_app/features/sales/bloc/sales_state.dart';
import 'package:sales_app/features/sales/models/line_edit.dart';

import 'package:sales_app/features/sales/presentaion/widgets/buttom_summary_overlay.dart';
import 'package:sales_app/features/sales/presentaion/widgets/cart_item_card.dart';
import 'package:sales_app/features/sales/presentaion/widgets/customer_seletor.dart';
import 'package:sales_app/features/sales/presentaion/widgets/empty_cart_view.dart';

import 'package:sales_app/utils/platform_helper.dart';
import 'package:sales_app/config/config.dart';
import 'package:sales_app/widgets/scanner_overlay.dart';
import 'package:sales_app/utils/interaction_lock.dart';

// Currency settings
import 'package:sales_app/utils/currency.dart';
import 'package:sales_app/features/settings/bloc/settings_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_state.dart';
import 'package:sales_app/features/settings/data/app_settings.dart';

class ProductCartScreen extends StatefulWidget {
  final VoidCallback? onCheckout;
  final VoidCallback? onCancel;

  const ProductCartScreen({
    super.key,
    this.onCheckout,
    this.onCancel,
  });

  @override
  State<ProductCartScreen> createState() => _ProductCartScreenState();
}

class _ProductCartScreenState extends State<ProductCartScreen> with TickerProviderStateMixin {
  // Controllers
  final _barcodeController = TextEditingController();
  final _focusNode = FocusNode();
  final _mobileScannerController = MobileScannerController();
  final _customerSearchCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  // State
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _loadingCustomers = false;
  bool _showScanner = false;
  bool _isSubmitting = false;
  String? _barcodeError;
  String? _customerError;
  Product? _selectedProduct;
  Timer? _scanDebouncer;
  final Map<int, LineEdit> _lineEdits = {};

  @override
  void initState() {
    super.initState();
    // Prevent background refreshes while the cart overlay is active
    InteractionLock.instance.isInteracting.value = true;

    if (PlatformHelper.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
    _loadCustomers();
    _paidAmountCtrl.addListener(_requestRebuild);
    _discountCtrl.addListener(_requestRebuild);
  }

  @override
  void dispose() {
    // Clear interacting flag
    InteractionLock.instance.isInteracting.value = false;

    _barcodeController.dispose();
    _focusNode.dispose();
    _mobileScannerController.dispose();
    _scanDebouncer?.cancel();
    _customerSearchCtrl.dispose();
    _paidAmountCtrl.dispose();
    _discountCtrl.dispose();
    for (final e in _lineEdits.values) {
      e.dispose();
    }
    super.dispose();
  }

  /* ------------------------------ Currency helpers ------------------------------ */

  int _fractionDigits() {
    final st = context.read<SettingsBloc>().state;
    if (st is SettingsLoaded) return st.settings.fractionDigits;
    if (st is SettingsSaved) return st.settings.fractionDigits;
    return AppSettings.fallback.fractionDigits;
  }

  String _currencySymbol() {
    // Take the first token returned by CurrencyFmt.format as the symbol
    final sample = CurrencyFmt.format(context, 0);
    final parts = sample.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  // Parse user-entered money safely (accepts "CF 1,234.50", "1 234,50", "1234.5", etc.)
  double _parseAmount(String raw) {
    if (raw.isEmpty) return 0.0;
    final sym = _currencySymbol();
    var v = raw.trim();
    if (sym.isNotEmpty) v = v.replaceAll(sym, '');
    // Remove spaces and thousand separators, normalize comma to dot if it's the only decimal separator
    v = v.replaceAll(RegExp(r'\s'), '');
    // If string has both '.' and ',', assume ',' is thousands and '.' is decimal; remove commas.
    if (v.contains('.') && v.contains(',')) {
      v = v.replaceAll(',', '');
    } else if (v.contains(',') && !v.contains('.')) {
      // Assume comma as decimal separator
      v = v.replaceAll(',', '.');
    }
    // Remove any character that's not digit, dot, or minus.
    v = v.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(v) ?? 0.0;
  }

  /* -------------------------------- Data loading -------------------------------- */

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    try {
      final svc = CustomerService(baseUrl: AppConfig.baseUrl);
      final list = await svc.getCustomers(page: 1, limit: 500);
      setState(() => _customers = list);
    } catch (e) {
      debugPrint('[ProductCartScreen][_loadCustomers] $e');
    } finally {
      if (mounted) setState(() => _loadingCustomers = false);
    }
  }

  Future<void> _showCustomerSelector() async {
    final selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomerSelectorSheet(
        customers: _customers,
        selectedCustomer: _selectedCustomer,
        isLoading: _loadingCustomers,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
        _customerError = null;
      });
    }
  }

  /* ----------------------------- Cart and checkout ----------------------------- */

  void _handleBarcode(String barcode) {
    final value = barcode.trim();
    if (value.isEmpty) return;

    _scanDebouncer?.cancel();
    _scanDebouncer = Timer(const Duration(milliseconds: 250), () {
      setState(() => _barcodeError = null);
      try {
        context.read<SalesBloc>().add(AddItemFromBarcode(value));
      } catch (e, st) {
        _logAndToastError('AddItemFromBarcode', e, st);
      }
      _barcodeController.clear();
      HapticFeedback.mediumImpact();
    });
  }

  Future<void> _onCheckout() async {
    setState(() {
      _barcodeError = null;
      _customerError = null;
    });

    final customerId = _selectedCustomer?.id ?? 0;
    if (customerId <= 0) {
      setState(() => _customerError = 'Select a customer');
      return;
    }

    final paidAmount = _parseAmount(_paidAmountCtrl.text);
    final orderDiscountAmount = _parseAmount(_discountCtrl.text);

    final overrides = <LineOverride>[];
    final salesBloc = context.read<SalesBloc>();
    Map<Product, int> cart = {};
    final st = salesBloc.state;
    if (st is CartUpdated) cart = st.cart;

    for (final entry in cart.entries) {
      final product = entry.key;
      final le = _lineEdits[product.id];
      if (le == null) continue;

      final unitPrice = le.unitPriceCtrl.text.trim().isEmpty ? null : _parseAmount(le.unitPriceCtrl.text);
      overrides.add(LineOverride(productId: product.id, unitPrice: unitPrice));
    }

    _isSubmitting = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 120));
      context.read<SalesBloc>().add(AddSale(
        customerId: customerId,
        paidAmount: paidAmount,
        orderDiscountAmount: orderDiscountAmount,
        overrides: overrides,
      ));
    } catch (e, st) {
      _logAndToastError('Checkout', e, st);
    }
  }

  void _onCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Sale'),
        content: const Text('Are you sure? This will clear the cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.kError),
            onPressed: () {
              try {
                Navigator.pop(context);
                context.read<SalesBloc>().add(ResetCart());
                widget.onCancel?.call();
              } catch (e, st) {
                _logAndToastError('CancelSale', e, st);
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  /* ------------------------------------ UI ------------------------------------ */

  @override
  Widget build(BuildContext context) {
    // When scanning, present scanner screen
    if (_showScanner && PlatformHelper.isMobile) {
      return _buildScannerScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        title: const Text('Product Cart'),
        backgroundColor: AppColors.kPrimary,
        foregroundColor: AppColors.kTextOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onCancel,
            tooltip: 'Close Cart',
          ),
        ],
      ),
      bottomNavigationBar: BottomSummaryBar(
        paidAmountCtrl: _paidAmountCtrl,
        discountCtrl: _discountCtrl,
        // IMPORTANT: pass our currency-aware parser so the bar can accept "CF 1,000" etc.
        computeParseAmount: _parseAmount,
        computeSubtotalCallback: () {
          final salesState = context.read<SalesBloc>().state;
          final cart = (salesState is CartUpdated) ? salesState.cart : <Product, int>{};
          return _computeSubtotal(cart);
        },
        onCancel: _onCancel,
        onCheckout: _onCheckout,
        // If your BottomSummaryBar supports showing formatted totals internally,
        // it can call CurrencyFmt.format(context, ...) on the subtotal it computes via the callback above.
      ),
      body: _buildBody(),
    );
  }

  // Scanner screen
  Widget _buildScannerScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _showScanner = false),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _mobileScannerController,
            onDetect: (capture) {
              try {
                final barcode = capture.barcodes.first.rawValue;
                if (barcode != null && barcode.isNotEmpty) {
                  _handleBarcode(barcode);
                  setState(() => _showScanner = false);
                }
              } catch (e, st) {
                _logAndToastError('ScannerDetect', e, st);
              }
            },
          ),
          const ScannerOverlay(),
        ],
      ),
    );
  }

  // Body
  Widget _buildBody() {
    return BlocConsumer<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          _logAndToastError('SalesBloc', state.message);
        }
        if (state is SalesOperationSuccess) {
          _closeAnyDialogSafely();
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kSuccess),
          );
          widget.onCheckout?.call();
        }
        if (state is SalesLoaded) {
          _closeAnyDialogSafely();
        }
      },
      builder: (context, salesState) {
        Map<Product, int> cart = {};
        if (salesState is CartUpdated) cart = salesState.cart;

        _syncLineEdits(cart);

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(cart)),
            if (cart.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyCartView(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.padding),
                sliver: SliverList.builder(
                  itemCount: cart.length,
                  itemBuilder: (_, i) => CartItemCard(
                    entry: cart.entries.elementAt(i),
                    lineEdit: _lineEdits[cart.entries.elementAt(i).key.id]!,
                    onQuantityChanged: (product, qty) {
                      context.read<SalesBloc>().add(UpdateItemQuantity(product, qty));
                    },
                    onRemove: (product) {
                      context.read<SalesBloc>().add(UpdateItemQuantity(product, 0));
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(Map<Product, int> cart) {
    final media = MediaQuery.of(context);
    final isSmall = media.size.width < AppSizes.mobileBreakpoint;

    return Container(
      padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Customer Selection
          ElevatedButton.icon(
            onPressed: _showCustomerSelector,
            icon: const Icon(Icons.person_search),
            label: Text(_selectedCustomer?.name ?? 'Select Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.kTextPrimary,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: _customerError != null ? AppColors.kError : Colors.grey.shade300),
              ),
            ),
          ),
          if (_customerError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(_customerError!, style: TextStyle(color: AppColors.kError, fontSize: 12)),
            ),
          if (_selectedCustomer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InputChip(
                avatar: CircleAvatar(
                  backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                  child: Text(_selectedCustomer!.name[0].toUpperCase()),
                ),
                label: Text(_selectedCustomer!.name),
                onDeleted: () => setState(() => _selectedCustomer = null),
              ),
            ),

          const SizedBox(height: AppSizes.padding),

          // Barcode Scanner
          Row(
            children: [
              Expanded(
                child: RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: (event) {
                    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      _handleBarcode(_barcodeController.text);
                    }
                  },
                  child: TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Scan or enter barcode',
                      errorText: _barcodeError,
                      prefixIcon: const Icon(Icons.qr_code),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: _handleBarcode,
                  ),
                ),
              ),
              if (PlatformHelper.isMobile) ...[
                const SizedBox(width: AppSizes.padding),
                FilledButton.icon(
                  onPressed: () => setState(() => _showScanner = true),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSizes.padding),

          // Manual Product Selection
          BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, state) {
              if (state is ProductsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductsLoaded) {
                return DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  isExpanded: true,
                  menuMaxHeight: 300,
                  decoration: const InputDecoration(
                    labelText: 'Add product manually',
                    prefixIcon: Icon(Icons.add_shopping_cart),
                    border: OutlineInputBorder(),
                  ),
                  items: state.products
                      .map((p) => DropdownMenuItem<Product>(
                            value: p,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (product) {
                    if (product != null) {
                      context.read<SalesBloc>().add(AddItemToCart(product));
                      setState(() => _selectedProduct = null);
                    }
                  },
                );
              }
              if (state is ProductsError) {
                return Text(state.message, style: const TextStyle(color: AppColors.kError));
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  /* ---------------------------------- Helpers --------------------------------- */

  void _requestRebuild() {
    if (mounted) setState(() {});
  }

  double _computeSubtotal(Map<Product, int> cart) {
    double total = 0;
    for (final e in cart.entries) {
      final product = e.key;
      final qty = e.value;
      final le = _lineEdits[product.id];
      double unitPrice = product.price ?? 0.0;
      if (le?.unitPriceCtrl.text.isNotEmpty == true) {
        unitPrice = _parseAmount(le!.unitPriceCtrl.text);
      }
      total += unitPrice * qty;
    }
    return total;
  }

  void _syncLineEdits(Map<Product, int> cart) {
    final existingKeys = _lineEdits.keys.toSet();
    final neededKeys = cart.keys.map((p) => p.id).toSet();

    for (final k in existingKeys.difference(neededKeys)) {
      _lineEdits[k]?.dispose();
      _lineEdits.remove(k);
    }

    final digits = _fractionDigits();

    for (final entry in cart.entries) {
      final p = entry.key;
      final qty = entry.value;
      _lineEdits.putIfAbsent(p.id, () => LineEdit());
      final le = _lineEdits[p.id]!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final defaultPrice = (p.price ?? 0.0).toStringAsFixed(digits);
        if (le.unitPriceCtrl.text.isEmpty) {
          le.unitPriceCtrl.text = defaultPrice;
        }
        final qtyStr = qty.toString();
        if (le.qtyCtrl.text != qtyStr) {
          le.qtyCtrl.text = qtyStr;
        }
      });
    }
  }

  void _logAndToastError(String where, Object error, [StackTrace? st]) {
    debugPrint('[ProductCartScreen][$where] $error');
    if (st != null) debugPrint(st.toString());

    if (mounted) {
      _closeAnyDialogSafely();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().isEmpty ? 'Unexpected error' : error.toString()),
          backgroundColor: AppColors.kError,
        ),
      );
    }
  }

  void _closeAnyDialogSafely() {
    if (_isSubmitting) {
      _isSubmitting = false;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}