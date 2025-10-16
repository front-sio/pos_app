import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Screens
import 'package:sales_app/features/customers/presentation/customers_screen.dart';
import 'package:sales_app/features/suppliers/presentation/suppliers_screen.dart';
import 'package:sales_app/features/products/presentation/products_screen.dart';
import 'package:sales_app/features/purchases/presentation/purchases_screen.dart';
import 'package:sales_app/features/sales/presentaion/product_cart_screen.dart' as cart;
import 'package:sales_app/features/sales/presentaion/sales_screen.dart';
import 'package:sales_app/features/screens/dashboard_screen.dart';
import 'package:sales_app/features/profits/presentation/profit_tracker_screen.dart';
import 'package:sales_app/features/purchases/presentation/new_purchase_screen.dart';
import 'package:sales_app/features/screens/reports/reports_screen.dart';
import 'package:sales_app/features/screens/settings/settings_screen.dart';
import 'package:sales_app/features/stocks/presentation/stock_screen.dart';
import 'package:sales_app/features/stocks/presentation/stock_overlay_screen.dart';
import 'package:sales_app/features/screens/users/users_screen.dart';
import 'package:sales_app/features/returns/presentation/returns_screen.dart';

// Invoices
import 'package:sales_app/features/invoices/presentation/invoices_screen.dart';
import 'package:sales_app/features/invoices/presentation/invoice_overlay_screen.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';

// Models/Utils
import 'package:sales_app/models/settings.dart';
import 'package:sales_app/utils/responsive.dart';
import 'package:sales_app/utils/keyboard_shortcuts.dart';

// Widgets
import 'package:sales_app/widgets/app_bar.dart';
import 'package:sales_app/widgets/sidebar.dart';

// Products feature
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/presentation/product_overlay_screen.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_event.dart';
import 'package:sales_app/features/products/services/product_service.dart';

// Customers/Suppliers overlay contracts
import 'package:sales_app/features/customers/data/customer_model.dart';
import 'package:sales_app/features/customers/presentation/customer_overlay_screen.dart';
import 'package:sales_app/features/customers/bloc/customer_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';

import 'package:sales_app/features/suppliers/data/supplier_model.dart';
import 'package:sales_app/features/suppliers/presentation/supplier_overlay_screen.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_bloc.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_event.dart';

import 'package:sales_app/constants/colors.dart';

class AdminScaffold extends StatefulWidget {
  final String initialPage;

  const AdminScaffold({super.key, this.initialPage = "Dashboard"});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> with TickerProviderStateMixin {
  late String activeMenu;
  late AppSettings appSettings;

  // Overlays
  bool _showProductCart = false;
  bool _showNewPurchase = false;
  bool _showStockOverlay = false;
  bool _showProductOverlay = false;
  bool _showCustomerOverlay = false;
  bool _showSupplierOverlay = false;
  bool _showInvoiceOverlay = false; // NEW

  // Overlay payloads
  Product? _stockProduct;
  StockOverlayMode _stockMode = StockOverlayMode.view;

  Product? _productOverlayProduct; // nullable to allow create
  ProductOverlayMode _productOverlayMode = ProductOverlayMode.view;

  Customer? _customerOverlayCustomer; // nullable to allow create
  CustomerOverlayMode _customerOverlayMode = CustomerOverlayMode.view;

  Supplier? _supplierOverlaySupplier; // nullable to allow create
  SupplierOverlayMode _supplierOverlayMode = SupplierOverlayMode.view;

  int? _invoiceOverlayId; // NEW: invoice id payload

  // Shared ProductsBloc so screen and overlay use the same instance
  late final ProductsBloc _productsBloc;

  // Overlay animations (shared)
  late final AnimationController _overlayCtrl;
  late final Animation<double> _backdropOpacity;
  late final Animation<Offset> _sheetOffset;

  // Focus management for overlay
  final FocusScopeNode _overlayFocusScope = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    activeMenu = widget.initialPage;

    appSettings = AppSettings(
      appName: "Sales Business App",
      primaryColorValue: 0xFF1E88E5,
      brandLogoUrl: null,
      appIconUrl: null,
    );

    // Instantiate ProductsBloc here so overlays can access it
    final productService = context.read<ProductService>();
    _productsBloc = ProductsBloc(productService: productService)..add(FetchProductsPage(1, 20));

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _backdropOpacity = CurvedAnimation(
      parent: _overlayCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _sheetOffset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_overlayCtrl);
  }

  @override
  void dispose() {
    _overlayCtrl.dispose();
    _overlayFocusScope.dispose();
    _productsBloc.close();
    super.dispose();
  }

  Widget _getPage(String menu) {
    switch (menu) {
      case "Dashboard":
        return const DashboardScreen();
      case "Users":
        return const UsersScreen();
      case "Sales":
        return SalesScreen(onAddNewSale: _openProductCart);
      case "Stock":
        return StockScreen(onOpenOverlay: _openStockOverlay);
      case "Customers":
        return CustomersScreen(onOpenOverlay: _openCustomerOverlay);
      case "Suppliers":
        return SuppliersScreen(onOpenOverlay: _openSupplierOverlay);
      case "Products":
        return BlocProvider.value(
          value: _productsBloc,
          child: ProductsScreen(onOpenOverlay: _openProductOverlay),
        );
      case "Purchases":
        return PurchasesScreen(onAddNewPurchase: _openNewPurchase);
      case "Invoices": // NEW
        return InvoicesScreen(onOpenOverlay: _openInvoiceOverlay);
      case "Profit Tracker":
        return const ProfitTrackerScreen();
      case "Reports":
        return const ReportsScreen();
      case "Settings":
        return SettingsScreen(settings: appSettings);
      case "Returns":
        return const ReturnsScreen();
      default:
        return const DashboardScreen();
    }
  }

  Future<void> _openProductCart() async {
    if (activeMenu != "Sales") setState(() => activeMenu = "Sales");
    setState(() {
      _hideAllOverlays();
      _showProductCart = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  Future<void> _openNewPurchase() async {
    if (activeMenu != "Purchases") setState(() => activeMenu = "Purchases");
    setState(() {
      _hideAllOverlays();
      _showNewPurchase = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  Future<void> _openStockOverlay(Product product, StockOverlayMode mode) async {
    if (activeMenu != "Stock") setState(() => activeMenu = "Stock");
    setState(() {
      _hideAllOverlays();
      _stockProduct = product;
      _stockMode = mode;
      _showStockOverlay = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  // Product overlay opener (product can be null for create)
  Future<void> _openProductOverlay(Product? product, ProductOverlayMode mode) async {
    if (activeMenu != "Products") setState(() => activeMenu = "Products");
    setState(() {
      _hideAllOverlays();
      _productOverlayProduct = product;
      _productOverlayMode = mode;
      _showProductOverlay = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  // Customer overlay opener (customer can be null for create)
  Future<void> _openCustomerOverlay(Customer? customer, CustomerOverlayMode mode) async {
    if (activeMenu != "Customers") setState(() => activeMenu = "Customers");
    setState(() {
      _hideAllOverlays();
      _customerOverlayCustomer = customer;
      _customerOverlayMode = mode;
      _showCustomerOverlay = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  // Supplier overlay opener (supplier can be null for create)
  Future<void> _openSupplierOverlay(Supplier? supplier, SupplierOverlayMode mode) async {
    if (activeMenu != "Suppliers") setState(() => activeMenu = "Suppliers");
    setState(() {
      _hideAllOverlays();
      _supplierOverlaySupplier = supplier;
      _supplierOverlayMode = mode;
      _showSupplierOverlay = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  // NEW: Invoice overlay opener
  Future<void> _openInvoiceOverlay(Invoice invoice) async {
    if (activeMenu != "Invoices") setState(() => activeMenu = "Invoices");
    setState(() {
      _hideAllOverlays();
      _invoiceOverlayId = invoice.id;
      _showInvoiceOverlay = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  void _hideAllOverlays() {
    _showProductCart = false;
    _showNewPurchase = false;
    _showStockOverlay = false;
    _showProductOverlay = false;
    _showCustomerOverlay = false;
    _showSupplierOverlay = false;
    _showInvoiceOverlay = false; // NEW
  }

  void _focusOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_overlayFocusScope.hasFocus) {
        _overlayFocusScope.requestFocus(FocusNode());
      }
    });
  }

  Future<void> _closeOverlay() async {
    await _overlayCtrl.reverse();
    if (mounted) {
      setState(() => _hideAllOverlays());
    }
  }

  void _onMenuSelected(String menu) {
    setState(() {
      activeMenu = menu;
    });
    // Close any visible overlay immediately (no confirm)
    if (_anyOverlayVisible()) {
      _closeOverlay();
    }
  }

  bool _anyOverlayVisible() =>
      _showProductCart ||
      _showNewPurchase ||
      _showStockOverlay ||
      _showProductOverlay ||
      _showCustomerOverlay ||
      _showSupplierOverlay ||
      _showInvoiceOverlay; // NEW

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    // Base shortcuts
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const OpenSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const OpenSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewSaleIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN): const NewSaleIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN): const NewPurchaseIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN): const NewPurchaseIntent(),
    };

    // IMPORTANT: Prevent Backspace and BrowserBack from popping routes when an overlay is open.
    // TextFields consume backspace before it reaches here, so typing still works.
    if (_anyOverlayVisible()) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.backspace)] = const DoNothingAndStopPropagationIntent();
      shortcuts[LogicalKeySet(LogicalKeyboardKey.browserBack)] = const DoNothingAndStopPropagationIntent();
    }

    final actions = <Type, Action<Intent>>{
      OpenSearchIntent: OpenSearchAction(context),
      // Close overlays immediately on ESC/back (no confirm)
      DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) {
        if (_anyOverlayVisible()) {
          _closeOverlay();
        }
        return null;
      }),
      NewSaleIntent: CallbackAction<NewSaleIntent>(onInvoke: (_) {
        if (activeMenu == "Sales") _openProductCart();
        return null;
      }),
      NewPurchaseIntent: CallbackAction<NewPurchaseIntent>(onInvoke: (_) {
        if (activeMenu == "Purchases") _openNewPurchase();
        return null;
      }),
      // Wire DoNothing intents so the framework consumes the key
      DoNothingAndStopPropagationIntent: DoNothingAction(consumesKey: true),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: FocusableActionDetector(
          child: PopScope(
            canPop: !_anyOverlayVisible(),
            onPopInvoked: (didPop) {
              if (!didPop && _anyOverlayVisible()) {
                // Close overlay without confirmation
                _closeOverlay();
              }
            },
            child: Scaffold(
              drawer: isDesktop
                  ? null
                  : Sidebar(
                      activeMenu: activeMenu,
                      onMenuSelected: (menu) {
                        _onMenuSelected(menu);
                        Navigator.pop(context);
                      },
                    ),
              body: Row(
                children: [
                  if (isDesktop)
                    Sidebar(
                      activeMenu: activeMenu,
                      onMenuSelected: _onMenuSelected,
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            const AdminAppBar(),
                            Expanded(
                              child: AbsorbPointer(
                                absorbing: _anyOverlayVisible(),
                                child: Semantics(
                                  container: true,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      final offset = Tween<Offset>(
                                        begin: const Offset(0.02, 0),
                                        end: Offset.zero,
                                      ).animate(animation);
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(position: offset, child: child),
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey(activeMenu),
                                      child: _getPage(activeMenu),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Sales cart overlay
                        if (_showProductCart && activeMenu == "Sales")
                          _OverlaySheet(
                            controller: _overlayCtrl,
                            backdropOpacity: _backdropOpacity,
                            sheetOffset: _sheetOffset,
                            onBackdropTap: _closeOverlay, // close immediately
                            isDesktop: isDesktop,
                            focusScopeNode: _overlayFocusScope,
                            child: cart.ProductCartScreen(
                              onCheckout: _closeOverlay,
                              onCancel: _closeOverlay, // close immediately
                            ),
                          ),

                        // New purchase overlay
                        if (_showNewPurchase && activeMenu == "Purchases")
                          _OverlaySheet(
                            controller: _overlayCtrl,
                            backdropOpacity: _backdropOpacity,
                            sheetOffset: _sheetOffset,
                            onBackdropTap: _closeOverlay,
                            isDesktop: isDesktop,
                            focusScopeNode: _overlayFocusScope,
                            child: NewPurchaseScreen(
                              onSaved: _closeOverlay,
                              onCancel: _closeOverlay,
                            ),
                          ),

                        // Stock overlay
                        if (_showStockOverlay && activeMenu == "Stock" && _stockProduct != null)
                          _OverlaySheet(
                            controller: _overlayCtrl,
                            backdropOpacity: _backdropOpacity,
                            sheetOffset: _sheetOffset,
                            onBackdropTap: _closeOverlay,
                            isDesktop: isDesktop,
                            focusScopeNode: _overlayFocusScope,
                            child: StockOverlayScreen(
                              product: _stockProduct!,
                              mode: _stockMode,
                              onSaved: _closeOverlay,
                              onCancel: _closeOverlay,
                            ),
                          ),

                        // Product overlay (supports create with null product)
                        if (_showProductOverlay && activeMenu == "Products")
                          BlocProvider.value(
                            value: _productsBloc,
                            child: _OverlaySheet(
                              controller: _overlayCtrl,
                              backdropOpacity: _backdropOpacity,
                              sheetOffset: _sheetOffset,
                              onBackdropTap: _closeOverlay,
                              isDesktop: isDesktop,
                              focusScopeNode: _overlayFocusScope,
                              child: ProductOverlayScreen(
                                product: _productOverlayProduct,
                                mode: _productOverlayMode,
                                onSaved: _closeOverlay,
                                onCancel: _closeOverlay,
                              ),
                            ),
                          ),

                        // Customer overlay
                        if (_showCustomerOverlay && activeMenu == "Customers")
                          BlocProvider.value(
                            value: context.read<CustomerBloc>(),
                            child: _OverlaySheet(
                              controller: _overlayCtrl,
                              backdropOpacity: _backdropOpacity,
                              sheetOffset: _sheetOffset,
                              onBackdropTap: _closeOverlay,
                              isDesktop: isDesktop,
                              focusScopeNode: _overlayFocusScope,
                              child: CustomerOverlayScreen(
                                customer: _customerOverlayCustomer,
                                mode: _customerOverlayMode,
                                onSaved: () {
                                  _closeOverlay();
                                  // Ensure list is fresh when returning
                                  context.read<CustomerBloc>().add(FetchCustomersPage(1, 20));
                                },
                                onCancel: _closeOverlay,
                              ),
                            ),
                          ),

                        // Supplier overlay
                        if (_showSupplierOverlay && activeMenu == "Suppliers")
                          BlocProvider.value(
                            value: context.read<SupplierBloc>(),
                            child: _OverlaySheet(
                              controller: _overlayCtrl,
                              backdropOpacity: _backdropOpacity,
                              sheetOffset: _sheetOffset,
                              onBackdropTap: _closeOverlay,
                              isDesktop: isDesktop,
                              focusScopeNode: _overlayFocusScope,
                              child: SupplierOverlayScreen(
                                supplier: _supplierOverlaySupplier,
                                mode: _supplierOverlayMode,
                                onSaved: () {
                                  _closeOverlay();
                                  // Ensure list is fresh when returning
                                  context.read<SupplierBloc>().add(FetchSuppliersPage(1, 20));
                                },
                                onCancel: _closeOverlay,
                              ),
                            ),
                          ),

                        // NEW: Invoice overlay
                        if (_showInvoiceOverlay && activeMenu == "Invoices" && _invoiceOverlayId != null)
                          _OverlaySheet(
                            controller: _overlayCtrl,
                            backdropOpacity: _backdropOpacity,
                            sheetOffset: _sheetOffset,
                            onBackdropTap: _closeOverlay,
                            isDesktop: isDesktop,
                            focusScopeNode: _overlayFocusScope,
                            child: InvoiceOverlayScreen(
                              invoiceId: _invoiceOverlayId!,
                              onClose: _closeOverlay,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlaySheet extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> backdropOpacity;
  final Animation<Offset> sheetOffset;
  final VoidCallback onBackdropTap;
  final bool isDesktop;
  final FocusScopeNode focusScopeNode;
  final Widget child;

  const _OverlaySheet({
    required this.controller,
    required this.backdropOpacity,
    required this.sheetOffset,
    required this.onBackdropTap,
    required this.isDesktop,
    required this.focusScopeNode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final widthFactor = isDesktop ? 0.7 : 1.0;
    final heightFactor = isDesktop ? 0.92 : 1.0;

    // Adaptive scrim for dark/light
    final Color scrimColor = isDark ? Colors.black.withOpacity(0.40) : Colors.black.withOpacity(0.15);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            // Backdrop scrim
            Semantics(
              label: 'Overlay backdrop',
              button: true,
              child: GestureDetector(
                onTap: onBackdropTap,
                child: FadeTransition(
                  opacity: backdropOpacity,
                  child: Container(color: scrimColor),
                ),
              ),
            ),
            // Sheet
            Center(
              child: FractionallySizedBox(
                widthFactor: widthFactor,
                heightFactor: heightFactor,
                child: SlideTransition(
                  position: sheetOffset,
                  child: FocusScope(
                    node: focusScopeNode,
                    autofocus: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isDesktop ? 16 : 0),
                      child: Material(
                        color: cs.surface,
                        elevation: isDesktop ? 6 : 0,
                        clipBehavior: Clip.antiAlias,
                        child: SafeArea(
                          top: !isDesktop,
                          bottom: !isDesktop,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DismissIntent extends Intent { const DismissIntent(); }
class NewSaleIntent extends Intent { const NewSaleIntent(); }
class NewPurchaseIntent extends Intent { const NewPurchaseIntent(); }