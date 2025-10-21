import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Screens
import 'package:sales_app/features/customers/presentation/customers_screen.dart';
import 'package:sales_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:sales_app/features/suppliers/presentation/suppliers_screen.dart';
import 'package:sales_app/features/products/presentation/products_screen.dart';
import 'package:sales_app/features/purchases/presentation/purchases_screen.dart';
import 'package:sales_app/features/sales/presentaion/product_cart_screen.dart' as cart;
import 'package:sales_app/features/sales/presentaion/sales_screen.dart';
import 'package:sales_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:sales_app/features/profits/presentation/profit_tracker_screen.dart';
import 'package:sales_app/features/purchases/presentation/new_purchase_screen.dart';
import 'package:sales_app/features/reports/reports_screen.dart';
import 'package:sales_app/features/screens/settings/settings_screen.dart';
import 'package:sales_app/features/stocks/presentation/stock_screen.dart';
import 'package:sales_app/features/stocks/presentation/stock_overlay_screen.dart';
import 'package:sales_app/features/screens/users/users_screen.dart';
import 'package:sales_app/features/returns/presentation/returns_screen.dart';

// Invoices
import 'package:sales_app/features/invoices/presentation/invoices_screen.dart';
import 'package:sales_app/features/invoices/presentation/invoice_overlay_screen.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';
import 'package:sales_app/features/users/presentation/pages/users_admin_screen.dart';

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

import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/rbac/rbac.dart';

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
  bool _showInvoiceOverlay = false;

  // Overlay payloads
  Product? _stockProduct;
  StockOverlayMode _stockMode = StockOverlayMode.view;

  Product? _productOverlayProduct;
  ProductOverlayMode _productOverlayMode = ProductOverlayMode.view;

  Customer? _customerOverlayCustomer;
  CustomerOverlayMode _customerOverlayMode = CustomerOverlayMode.view;

  Supplier? _supplierOverlaySupplier;
  SupplierOverlayMode _supplierOverlayMode = SupplierOverlayMode.view;

  int? _invoiceOverlayId;

  // Shared ProductsBloc so screen and overlay use the same instance
  late final ProductsBloc _productsBloc;

  // Overlay animations (shared)
  late final AnimationController _overlayCtrl;
  late final Animation<double> _backdropOpacity;
  late final Animation<Offset> _sheetOffset;

  // Focus management for overlay
  final FocusScopeNode _overlayFocusScope = FocusScopeNode();

  // Global Focus to intercept keys (backspace/browserBack) only when overlays visible and not typing
  late final FocusNode _rootKeyFocus;

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

    _rootKeyFocus = FocusNode(debugLabel: 'AdminScaffoldRootKeyFocus');
  }

  @override
  void dispose() {
    _overlayCtrl.dispose();
    _overlayFocusScope.dispose();
    _rootKeyFocus.dispose();
    _productsBloc.close();
    super.dispose();
  }

  // ===== RBAC helpers =====

  bool _can(String permission) => Rbac.can(context, permission);

  bool _guard(String permission, String featureName) {
    if (_can(permission)) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Access denied: $featureName'), backgroundColor: AppColors.kError),
    );
    return false;
  }

  // ===== Pages =====

  Widget _getPage(String menu) {
    switch (menu) {
      case "Dashboard":
        return const DashboardScreen();
      case "Profile":
        return const ProfileScreen();
      case "Users":
        return _can("users:view") ? const UsersAdminScreen() : _forbidden();
      case "Sales":
        return _can("sales:view") ? SalesScreen(onAddNewSale: _openProductCart) : _forbidden();
      case "Stock":
        return _can("stock:view") ? StockScreen(onOpenOverlay: _openStockOverlay) : _forbidden();
      case "Customers":
        return _can("customers:view") ? CustomersScreen(onOpenOverlay: _openCustomerOverlay) : _forbidden();
      case "Suppliers":
        return _can("suppliers:view") ? SuppliersScreen(onOpenOverlay: _openSupplierOverlay) : _forbidden();
      case "Products":
        return _can("products:view")
            ? BlocProvider.value(
                value: _productsBloc,
                child: ProductsScreen(onOpenOverlay: _openProductOverlay),
              )
            : _forbidden();
      case "Purchases":
        return _can("purchases:view") ? PurchasesScreen(onAddNewPurchase: _openNewPurchase) : _forbidden();
      case "Invoices":
        return _can("invoices:view") ? InvoicesScreen(onOpenOverlay: _openInvoiceOverlay) : _forbidden();
      case "Profit Tracker":
        return _can("profits:view") ? const ProfitTrackerScreen() : _forbidden();
      case "Reports":
        return _can("reports:view") ? const ReportsScreen() : _forbidden();
      case "Settings":
        return _can("settings:view") ? SettingsScreen(settings: appSettings) : _forbidden();
      case "Returns":
        return _can("returns:view") ? const ReturnsScreen() : _forbidden();
      default:
        return const DashboardScreen();
    }
  }

  Widget _forbidden() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock_outline, size: 64, color: cs.error),
        const SizedBox(height: 12),
        Text('403 — Forbidden', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('You do not have permission to view this page.', style: theme.textTheme.bodyMedium),
      ]),
    );
  }

  // ===== Overlay openings with RBAC guards =====

  Future<void> _openProductCart() async {
    if (!_guard("sales:create", "Create Sale")) return;
    if (activeMenu != "Sales") setState(() => activeMenu = "Sales");
    setState(() {
      _hideAllOverlays();
      _showProductCart = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  Future<void> _openNewPurchase() async {
    if (!_guard("purchases:create", "Create Purchase")) return;
    if (activeMenu != "Purchases") setState(() => activeMenu = "Purchases");
    setState(() {
      _hideAllOverlays();
      _showNewPurchase = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  Future<void> _openStockOverlay(Product product, StockOverlayMode mode) async {
    final needs = mode == StockOverlayMode.view ? "stock:view" : "stock:edit";
    if (!_guard(needs, "Stock")) return;
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

  Future<void> _openProductOverlay(Product? product, ProductOverlayMode mode) async {
    final needs = switch (mode) {
      ProductOverlayMode.create => "products:create",
      ProductOverlayMode.edit => "products:edit",
      _ => "products:view",
    };
    if (!_guard(needs, "Products")) return;
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

  Future<void> _openCustomerOverlay(Customer? customer, CustomerOverlayMode mode) async {
    final needs = switch (mode) {
      CustomerOverlayMode.create => "customers:create",
      CustomerOverlayMode.edit => "customers:edit",
      _ => "customers:view",
    };
    if (!_guard(needs, "Customers")) return;
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

  Future<void> _openSupplierOverlay(Supplier? supplier, SupplierOverlayMode mode) async {
    final needs = switch (mode) {
      SupplierOverlayMode.create => "suppliers:create",
      SupplierOverlayMode.edit => "suppliers:edit",
      _ => "suppliers:view",
    };
    if (!_guard(needs, "Suppliers")) return;
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

  Future<void> _openInvoiceOverlay(Invoice invoice) async {
    if (!_guard("invoices:view", "Invoices")) return;
    if (activeMenu != "Invoices") setState(() => activeMenu = "Invoices");
    setState(() {
      _hideAllOverlays();
      _invoiceOverlayId = invoice.id;
      _showInvoiceOverlay = true;
    });
    await _overlayCtrl.forward();
    _focusOverlay();
  }

  // ===== Overlay helpers =====

  void _hideAllOverlays() {
    _showProductCart = false;
    _showNewPurchase = false;
    _showStockOverlay = false;
    _showProductOverlay = false;
    _showCustomerOverlay = false;
    _showSupplierOverlay = false;
    _showInvoiceOverlay = false;
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
    // RBAC: prevent switching into pages user cannot view
    if (!Rbac.canMenu(context, menu)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access denied: $menu'), backgroundColor: AppColors.kError),
      );
      return;
    }

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
      _showInvoiceOverlay;

  // Detection for "typing in a text field?"
  bool _isTextEditingFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final ctx = focus.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;

    bool found = false;
    ctx.visitAncestorElements((ancestor) {
      if (ancestor.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    // Base shortcuts
    final Map<LogicalKeySet, Intent> shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const OpenSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const OpenSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewSaleIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN): const NewSaleIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN): const NewPurchaseIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN): const NewPurchaseIntent(),
    };

    // Intercept backspace/browserBack only when overlay is open and user not typing
    final actions = <Type, Action<Intent>>{
      OpenSearchIntent: OpenSearchAction(context),
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
      DoNothingAndStopPropagationIntent: DoNothingAction(consumesKey: true),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: Focus(
          focusNode: _rootKeyFocus,
          autofocus: true,
          onKey: (node, event) {
            if (!_anyOverlayVisible()) return KeyEventResult.ignored;
            if (event is! KeyDownEvent) return KeyEventResult.ignored;

            final key = event.logicalKey;

            if ((key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.browserBack) && !_isTextEditingFocused()) {
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: FocusableActionDetector(
            child: PopScope(
              canPop: !_anyOverlayVisible(),
              onPopInvoked: (didPop) {
                if (!didPop && _anyOverlayVisible()) {
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
                              onBackdropTap: _closeOverlay,
                              isDesktop: isDesktop,
                              focusScopeNode: _overlayFocusScope,
                              child: cart.ProductCartScreen(
                                onCheckout: _closeOverlay,
                                onCancel: _closeOverlay,
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

                          // Product overlay
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
                                    context.read<SupplierBloc>().add(FetchSuppliersPage(1, 20));
                                  },
                                  onCancel: _closeOverlay,
                                ),
                              ),
                            ),

                          // Invoice overlay
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
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12, width: 1)),
      ),
      child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
        if (state is AuthAuthenticated) {
          return Row(
            children: [
              GestureDetector(
                onTap: () {
                  _onMenuSelected("Profile");
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppSizes.avatarSize / 2,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onPrimary, size: AppSizes.normalIcon),
                    ),
                    const SizedBox(width: AppSizes.padding),
                    Expanded(
                      child: Text("${state.firstName} ${state.lastName}", overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Logout',
                icon: Icon(Icons.logout_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: AppSizes.normalIcon),
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      }),
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

class DismissIntent extends Intent {
  const DismissIntent();
}

class NewSaleIntent extends Intent {
  const NewSaleIntent();
}

class NewPurchaseIntent extends Intent {
  const NewPurchaseIntent();
}

// An intent used to consume keys without further propagation if needed elsewhere.
class DoNothingAndStopPropagationIntent extends Intent {
  const DoNothingAndStopPropagationIntent();
}