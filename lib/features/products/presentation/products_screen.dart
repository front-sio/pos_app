import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/features/products/services/realtime_product.dart';

import 'package:sales_app/utils/responsive.dart';
import 'package:sales_app/utils/interaction_lock.dart';
import 'package:sales_app/utils/currency.dart';
import 'package:sales_app/widgets/error_placeholder.dart';

import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_event.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';

import 'package:sales_app/features/products/presentation/product_overlay_screen.dart';
import 'package:sales_app/features/products/presentation/category_overlay_screen.dart';
import 'package:sales_app/features/products/presentation/unit_overlay_screen.dart';

class ProductsScreen extends StatefulWidget {
  final Future<void> Function(Product? product, ProductOverlayMode mode)? onOpenOverlay;

  const ProductsScreen({super.key, this.onOpenOverlay});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _limit = 20;

  List<CategoryOption> _categories = [];
  int? _selectedCategoryId;
  bool _loadingMeta = true;

  bool _isSearching = false;
  bool _isGridView = false; // Toggle between list and grid view

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Realtime
  final RealtimeProducts _rt = RealtimeProducts(debounce: const Duration(milliseconds: 500));
  StreamSubscription<String>? _rtSub;
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _refreshDebounce;
  static const Duration _refreshCooldown = Duration(milliseconds: 900);
  Timer? _safetyPoller;
  static const Duration _safetyPollEvery = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();

    final state = context.read<ProductsBloc>().state;
    if (state is! ProductsLoaded && state is! ProductsLoading) {
      context.read<ProductsBloc>().add(FetchProductsPage(1, _limit));
    }

    _loadMeta();
    _startRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    _stopRealtime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRealtime();
    } else if (state == AppLifecycleState.paused) {
      _stopRealtime();
    }
  }

  void _startRealtime() {
    _stopRealtime(); // clean previous

    _rt.connect();
    _rtSub = _rt.events.listen((type) {
      _scheduleThrottledRefresh();
    });

    _safetyPoller = Timer.periodic(_safetyPollEvery, (_) {
      if (InteractionLock.instance.isInteracting.value == true) return;
      _scheduleThrottledRefresh();
    });
  }

  void _stopRealtime() {
    _safetyPoller?.cancel();
    _safetyPoller = null;

    _refreshDebounce?.cancel();
    _refreshDebounce = null;

    _rtSub?.cancel();
    _rtSub = null;

    _rt.dispose();
  }

  void _scheduleThrottledRefresh() {
    if (InteractionLock.instance.isInteracting.value == true) return;

    final now = DateTime.now();
    final since = now.difference(_lastRefresh);
    if (since < _refreshCooldown) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(_refreshCooldown - since, () {
        _lastRefresh = DateTime.now();
        _currentPage = 1;
        context.read<ProductsBloc>().add(FetchProductsPage(1, _limit));
      });
      return;
    }
    _lastRefresh = now;
    _currentPage = 1;
    context.read<ProductsBloc>().add(FetchProductsPage(1, _limit));
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    try {
      final service = context.read<ProductService>();
      final cats = await service.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMeta = false);
      _snack('Failed to load categories: $e', error: true);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _currentPage++;
      context.read<ProductsBloc>().add(FetchProductsPage(_currentPage, _limit));
    }
  }

  double _getHorizontalPadding(BuildContext context) {
    if (Responsive.isMobile(context)) return 12;
    if (Responsive.isTablet(context)) return 20;
    return 24;
  }

  void _snack(String msg, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? cs.error : cs.primary));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSearchSection(context),
                    _buildCategoriesSection(context),
                  ],
                ),
              ),
              _buildProductList(context),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      expandedHeight: Responsive.isMobile(context) ? 100 : 70,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Products', style: theme.textTheme.headlineSmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.bold)),
        titlePadding: EdgeInsets.only(left: _getHorizontalPadding(context), bottom: 16),
      ),
      actions: [
        TextButton.icon(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, size: 18),
          label: Text(_isGridView ? 'List' : 'Grid'),
          onPressed: _toggleViewMode,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        IconButton(icon: const Icon(Icons.sort), onPressed: _showSortBottomSheet, tooltip: 'Sort'),
        IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterBottomSheet, tooltip: 'Filter'),
        TextButton.icon(
          icon: const Icon(Icons.category_outlined, size: 18),
          label: const Text('Category'),
          onPressed: _openCategoryOverlayCreate,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.straighten, size: 18),
          label: const Text('Unit'),
          onPressed: _openUnitOverlayCreate,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'export':
                _exportProducts();
                break;
              case 'settings':
                _openSettings();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.download, size: 20), SizedBox(width: 12), Text('Export')])),
            PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 12), Text('Settings')])),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding(context), vertical: 8),
      child: Card(
        elevation: theme.cardTheme.elevation ?? 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: _isSearching ? cs.primary : cs.onSurface.withOpacity(0.6)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _isSearching = false);
                        context.read<ProductsBloc>().add(SearchProducts(''));
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (query) {
              setState(() => _isSearching = query.isNotEmpty);
              context.read<ProductsBloc>().add(SearchProducts(query));
            },
            onSubmitted: (_) => HapticFeedback.lightImpact(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loadingMeta) {
      return SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
        ),
      );
    }

    // Simple horizontal list for all screen sizes
    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding(context)),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _categoryChip(label: 'All', selected: _selectedCategoryId == null, onTap: () => setState(() => _selectedCategoryId = null)),
          const SizedBox(width: 8),
          ..._categories.expand((c) sync* {
            yield _categoryChip(label: c.name, selected: _selectedCategoryId == c.id, onTap: () => setState(() => _selectedCategoryId = c.id));
            yield const SizedBox(width: 8);
          }).toList(),
        ],
      ),
    );
  }

  Widget _categoryChip({required String label, required bool selected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.cardColor,
      selectedColor: cs.primary.withOpacity(0.12),
      checkmarkColor: cs.primary,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
      labelStyle: TextStyle(color: selected ? cs.primary : cs.onSurface.withOpacity(0.7), fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
      elevation: selected ? 2 : 0,
      pressElevation: 0,
    );
  }

  Widget _buildProductList(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return SliverFillRemaining(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(color: cs.primary),
                const SizedBox(height: 16),
                Text('Loading products...', style: theme.textTheme.bodyMedium),
              ]),
            ),
          );
        }

        if (state is ProductsError) {
          return SliverFillRemaining(
            child: ErrorPlaceholder(
              onRetry: () => context.read<ProductsBloc>().add(FetchProductsPage(1, _limit)),
            ),
          );
        }

        if (state is ProductsLoaded) {
          final products = _applyCategoryFilter(state.products);

          if (products.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inventory_outlined, size: 64, color: cs.onSurface.withOpacity(0.35)),
                  const SizedBox(height: 16),
                  Text(_isSearching || _selectedCategoryId != null ? 'No products found' : 'No products yet',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _isSearching || _selectedCategoryId != null ? 'Try adjusting your search/filter' : 'Start by adding your first product',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (!_isSearching && _selectedCategoryId == null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(onPressed: () => _openOverlay(null, ProductOverlayMode.create), icon: const Icon(Icons.add), label: const Text('Add Product')),
                  ],
                ]),
              ),
            );
          }

          return _isGridView ? _buildGridProductList(products) : _buildMobileProductList(products);
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  List<Product> _applyCategoryFilter(List<Product> products) {
    if (_selectedCategoryId == null) return products;
    return products.where((p) {
      if (p.categoryId != null) return p.categoryId == _selectedCategoryId;
      final selected = _categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
      if (selected == null) return true;
      return (p.categoryName ?? '').toLowerCase() == selected.name.toLowerCase();
    }).toList();
  }

  Widget _buildMobileProductList(List<Product> products) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding(context)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 100 + (index * 50)),
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildProductCard(product, true),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildGridProductList(List<Product> products) {
    final crossAxisCount = Responsive.isMobile(context) ? 2 : (Responsive.isTablet(context) ? 3 : 4);
    return SliverPadding(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 100 + (index * 50)),
              child: _buildProductCard(product, false),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  void _openOverlay(Product? product, ProductOverlayMode mode) async {
    if (widget.onOpenOverlay != null) {
      await widget.onOpenOverlay!(product, mode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Overlay handler not provided.')));
    }
  }

  Widget _buildProductCard(Product product, bool isMobileList) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLowStock = product.quantity <= 10;
    final totalValue = ((product.totalValue ?? (product.quantity * product.pricePerQuantity)).clamp(0, double.infinity)).toDouble();

    final trailingMenu = PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'view':
            _openOverlay(product, ProductOverlayMode.view);
            break;
          case 'edit':
            _openOverlay(product, ProductOverlayMode.edit);
            break;
          case 'delete':
            _openOverlay(product, ProductOverlayMode.deleteConfirm);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'))),
        PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
        PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete), title: Text('Delete'))),
      ],
    );

    return Card(
      elevation: theme.cardTheme.elevation ?? 2,
      color: theme.cardColor,
      shadowColor: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openOverlay(product, ProductOverlayMode.view),
        borderRadius: BorderRadius.circular(16),
        child: isMobileList ? _buildMobileContent(product, isLowStock, totalValue, trailingMenu) : _buildGridContent(product, isLowStock, totalValue, trailingMenu),
      ),
    );
  }

  Widget _buildMobileContent(Product product, bool isLowStock, double totalValue, Widget trailingMenu) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.inventory, color: cs.primary, size: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(product.description ?? 'No description', style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: (isLowStock ? cs.error : Colors.green).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${product.quantity.toInt()} in stock', style: TextStyle(color: isLowStock ? cs.error : Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: cs.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      CurrencyFmt.format(context, totalValue),
                      style: theme.textTheme.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              CurrencyFmt.format(context, product.price ?? 0.0),
              style: theme.textTheme.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            trailingMenu,
          ]),
        ],
      ),
    );
  }

  Widget _buildGridContent(Product product, bool isLowStock, double totalValue, Widget trailingMenu) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.inventory, color: cs.primary, size: 40)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(product.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
            trailingMenu,
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: Text(product.description ?? 'No description', style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            CurrencyFmt.format(context, product.price ?? 0.0),
            style: theme.textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: cs.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  CurrencyFmt.format(context, totalValue),
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: (isLowStock ? cs.error : Colors.green).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${product.quantity.toInt()}', style: TextStyle(color: isLowStock ? cs.error : Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ]),
      ]),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _openOverlay(null, ProductOverlayMode.create),
      icon: const Icon(Icons.add),
      label: const Text('Add Product'),
      elevation: 6,
      heroTag: "addProduct",
    );
  }

  void _showSortBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Sort Products', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.sort_by_alpha), title: const Text('Name A-Z'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.attach_money), title: const Text('Price: Low to High'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.inventory), title: const Text('Stock: Low to High'), onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
    HapticFeedback.selectionClick();
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Filter Products', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.warning), title: const Text('Low Stock Only'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.check_circle), title: const Text('In Stock Only'), onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
    HapticFeedback.selectionClick();
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
    HapticFeedback.lightImpact();
  }

  void _exportProducts() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming soon!')));
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings feature coming soon!')));
  }

  Future<void> _openCategoryOverlayCreate() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: CategoryOverlayScreen(
            category: null,
            mode: CategoryOverlayMode.create,
            onSaved: () {
              Navigator.of(context).pop();
              _loadMeta();
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _openUnitOverlayCreate() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: UnitOverlayScreen(
            unit: null,
            mode: UnitOverlayMode.create,
            onSaved: () {
              Navigator.of(context).pop();
              _loadMeta();
              _snack('Unit created');
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

// Small extension to get .firstOrNull without importing collection package
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
