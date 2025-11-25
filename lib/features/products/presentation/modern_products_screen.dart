import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/advanced_feature_card.dart';
import '../../../widgets/universal_placeholder.dart';
import '../../../widgets/advanced_animations.dart';
import '../../../widgets/micro_interactions.dart';
import '../../../widgets/modern_button.dart';
import '../../../theme/theme_manager.dart';
import '../../../constants/colors.dart';
import '../../../utils/currency.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';
import '../data/product_model.dart';
import 'product_overlay_screen.dart';

class ModernProductsScreen extends StatefulWidget {
  const ModernProductsScreen({Key? key}) : super(key: key);

  @override
  State<ModernProductsScreen> createState() => _ModernProductsScreenState();
}

class _ModernProductsScreenState extends State<ModernProductsScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  bool _isGridView = false;
  String _sortBy = 'name';
  String _filterCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    context.read<ProductsBloc>().add(FetchProducts());
  }

  void _openProductForm(Product? product) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: BlocProvider.value(
            value: context.read<ProductsBloc>(),
            child: ProductOverlayScreen(
              product: product,
              mode: product == null 
                  ? ProductOverlayMode.create 
                  : ProductOverlayMode.edit,
              onSaved: () {
                Navigator.pop(context);
                _loadProducts();
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    HapticManager.trigger(HapticType.medium);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ModernButton(
            text: 'Delete',
            type: ModernButtonType.primary,
            backgroundColor: AppColors.kError,
            size: ModernButtonSize.small,
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductsBloc>().add(DeleteProductEvent(product.id));
              HapticManager.trigger(HapticType.success);
            },
          ),
        ],
      ),
    );
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    if (query.isEmpty) {
      _loadProducts();
    } else {
      context.read<ProductsBloc>().add(SearchProducts(query));
    }
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
    HapticManager.trigger(HapticType.light);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernAppBar(),
          _buildSearchAndFilters(),
          _buildProductsListView(),
        ],
      ),
      floatingActionButton: FloatingActionBubble(
        backgroundColor: ThemeManager().currentBusinessColors.primary,
        items: [
          FloatingActionItem(
            icon: Icons.add_box,
            onTap: () => _openProductForm(null),
            backgroundColor: ThemeManager().currentBusinessColors.secondary,
            tooltip: 'Add Product',
          ),
          FloatingActionItem(
            icon: Icons.qr_code_scanner,
            onTap: _scanBarcode,
            backgroundColor: ThemeManager().currentBusinessColors.warning,
            tooltip: 'Scan Barcode',
          ),
          FloatingActionItem(
            icon: Icons.file_upload,
            onTap: _importProducts,
            backgroundColor: ThemeManager().currentBusinessColors.success,
            tooltip: 'Import Products',
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildModernAppBar() {
    final businessColors = ThemeManager().currentBusinessColors;
    
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: businessColors.primary,
      actions: [
        IconButton(
          onPressed: _toggleView,
          icon: Icon(
            _isGridView ? Icons.view_list : Icons.grid_view,
            color: Colors.white,
          ),
          tooltip: _isGridView ? 'List View' : 'Grid View',
        ),
        IconButton(
          onPressed: _showSortOptions,
          icon: const Icon(Icons.sort, color: Colors.white),
          tooltip: 'Sort',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Products',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: businessColors.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Inventory',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            BlocBuilder<ProductsBloc, ProductsState>(
                              builder: (context, state) {
                                final count = state is ProductsLoaded 
                                    ? state.products.length 
                                    : 0;
                                return AnimatedCounter(
                                  value: count,
                                  suffix: ' products in stock',
                                  textStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search products, SKU, category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : IconButton(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Electronics', 'electronics'),
                  _buildFilterChip('Clothing', 'clothing'),
                  _buildFilterChip('Books', 'books'),
                  _buildFilterChip('Food', 'food'),
                  _buildFilterChip('Low Stock', 'low_stock'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterCategory == value;
    final businessColors = ThemeManager().currentBusinessColors;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _filterCategory = value;
          });
          HapticManager.trigger(HapticType.selection);
          _applyFilters();
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: businessColors.primary.withOpacity(0.2),
        checkmarkColor: businessColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? businessColors.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductsListView() {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return _buildLoadingState();
        }
        
        if (state is ProductsError) {
          return SliverFillRemaining(
            child: UniversalPlaceholder.error(
              message: state.message,
              onRetry: _loadProducts,
            ),
          );
        }
        
        if (state is ProductsLoaded) {
          final products = state.products;
          
          if (products.isEmpty) {
            return SliverFillRemaining(
              child: _isSearching
                  ? UniversalPlaceholder.noResults(
                      searchTerm: _searchController.text,
                      onClearSearch: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : UniversalPlaceholder.empty(
                      feature: 'products',
                      onCreate: () => _openProductForm(null),
                    ),
            );
          }
          
          return _isGridView 
              ? _buildProductsGrid(products)
              : _buildProductsListContent(products);
        }
        
        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildProductsListContent(List<Product> products) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AdvancedStaggeredList(
          children: products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return _ModernProductCard(
              product: product,
              animationDelay: index * 30,
              onTap: () => _openProductForm(product),
              onEdit: () => _openProductForm(product),
              onDelete: () => _deleteProduct(product),
              onDuplicate: () => _duplicateProduct(product),
            );
          }).toList(),
          animationType: AnimationType.slideUp,
          enablePullToRefresh: true,
          onRefresh: () async {
            _loadProducts();
          },
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    final screenSize = MediaQuery.of(context).size;
    final crossAxisCount = screenSize.width > 1200 ? 4 
        : screenSize.width > 800 ? 3 
        : screenSize.width > 600 ? 2 
        : 1;
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AdvancedStaggeredGrid(
          crossAxisCount: crossAxisCount,
          children: products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return _ModernProductGridCard(
              product: product,
              animationDelay: index * 20,
              onTap: () => _openProductForm(product),
              onEdit: () => _openProductForm(product),
              onDelete: () => _deleteProduct(product),
            );
          }).toList(),
          animationType: AnimationType.scale,
          childAspectRatio: 0.8,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          enablePullToRefresh: true,
          onRefresh: () async {
            _loadProducts();
          },
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isGridView
            ? AdvancedStaggeredGrid(
                crossAxisCount: 2,
                children: List.generate(6, (index) {
                  return AdvancedFeatureCard(
                    type: FeatureCardType.grid,
                    title: '',
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade300,
                    ),
                    isLoading: true,
                    animationDelay: index * 50,
                  );
                }),
                childAspectRatio: 0.8,
                shrinkWrap: true,
              )
            : Column(
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdvancedFeatureCard(
                      type: FeatureCardType.list,
                      title: '',
                      leading: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                      ),
                      trailing: Container(
                        width: 60, 
                        height: 20, 
                        color: Colors.grey.shade300,
                      ),
                      isLoading: true,
                      animationDelay: index * 100,
                    ),
                  );
                }),
              ),
      ),
    );
  }

  void _scanBarcode() {
    HapticManager.trigger(HapticType.medium);
    // Implement barcode scanning
  }

  void _importProducts() {
    HapticManager.trigger(HapticType.medium);
    // Implement product import
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('Name', 'name'),
              ('Price', 'price'),
              ('Stock', 'stock'),
              ('Category', 'category'),
              ('Recent', 'recent'),
            ].map((option) {
              return ListTile(
                title: Text(option.$1),
                trailing: _sortBy == option.$2 
                    ? Icon(Icons.check, color: ThemeManager().currentBusinessColors.primary)
                    : null,
                onTap: () {
                  setState(() => _sortBy = option.$2);
                  Navigator.pop(context);
                  _applySorting();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    // Implement filtering logic
  }

  void _applySorting() {
    // Implement sorting logic
  }

  void _duplicateProduct(Product product) {
    final duplicatedProduct = Product(
      id: 0,
      name: '${product.name} (Copy)',
      description: product.description,
      initialQuantity: product.initialQuantity,
      quantity: 0,
      pricePerQuantity: product.pricePerQuantity,
      price: product.price,
      barcode: null,
      categoryId: product.categoryId,
      unitName: product.unitName,
      unitId: product.unitId,
      location: product.location,
      reorderLevel: product.reorderLevel,
      supplier: product.supplier,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalValue: 0,
      categoryName: product.categoryName,
    );
    _openProductForm(duplicatedProduct);
  }
}

class _ModernProductCard extends StatelessWidget {
  final Product product;
  final int animationDelay;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _ModernProductCard({
    required this.product,
    required this.animationDelay,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final businessColors = ThemeManager().currentBusinessColors;
    final isLowStock = product.quantity <= product.reorderLevel;
    
    return AdvancedFeatureCard(
      type: FeatureCardType.list,
      title: product.name,
      subtitle: product.barcode ?? 'No barcode',
      description: product.description,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: businessColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: businessColors.primary.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: businessColors.primary,
          size: 24,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            CurrencyFmt.format(context, product.price ?? 0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: businessColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isLowStock ? AppColors.kError.withOpacity(0.1) : AppColors.kSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${product.quantity} in stock',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLowStock ? AppColors.kError : AppColors.kSuccess,
              ),
            ),
          ),
        ],
      ),
      badges: [
        if (isLowStock)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.kWarning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LOW STOCK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
      actions: const [
        FeatureCardAction.edit,
        FeatureCardAction.duplicate,
        FeatureCardAction.delete,
      ],
      onTap: onTap,
      onActionTap: (action) {
        switch (action) {
          case FeatureCardAction.edit:
            onEdit();
            break;
          case FeatureCardAction.delete:
            onDelete();
            break;
          case FeatureCardAction.duplicate:
            onDuplicate();
            break;
          default:
            break;
        }
      },
      animationDelay: animationDelay,
      accentColor: businessColors.primary,
      metadata: {
        'Price': CurrencyFmt.format(context, product.price ?? 0),
        'Unit Price': CurrencyFmt.format(context, product.pricePerQuantity),
        'Total Value': CurrencyFmt.format(context, product.totalValue ?? 0),
        'Stock': '${product.quantity} units',
      },
    );
  }
}

class _ModernProductGridCard extends StatelessWidget {
  final Product product;
  final int animationDelay;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ModernProductGridCard({
    required this.product,
    required this.animationDelay,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final businessColors = ThemeManager().currentBusinessColors;
    final isLowStock = product.quantity <= product.reorderLevel;
    
    return AdvancedFeatureCard(
      type: FeatureCardType.grid,
      title: product.name,
      subtitle: CurrencyFmt.format(context, product.price ?? 0),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: businessColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: businessColors.primary.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.inventory_2,
          color: businessColors.primary,
          size: 30,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLowStock ? AppColors.kError.withOpacity(0.1) : AppColors.kSuccess.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${product.quantity}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isLowStock ? AppColors.kError : AppColors.kSuccess,
          ),
        ),
      ),
      actions: const [
        FeatureCardAction.edit,
        FeatureCardAction.delete,
      ],
      onTap: onTap,
      onActionTap: (action) {
        switch (action) {
          case FeatureCardAction.edit:
            onEdit();
            break;
          case FeatureCardAction.delete:
            onDelete();
            break;
          default:
            break;
        }
      },
      animationDelay: animationDelay,
      accentColor: businessColors.primary,
    );
  }
}