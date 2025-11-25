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
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';
import '../data/sales_model.dart';
import 'product_cart_screen.dart';

class ModernSalesScreen extends StatefulWidget {
  const ModernSalesScreen({Key? key}) : super(key: key);

  @override
  State<ModernSalesScreen> createState() => _ModernSalesScreenState();
}

class _ModernSalesScreenState extends State<ModernSalesScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  String _filterStatus = 'all';
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSales() {
    context.read<SalesBloc>().add(LoadSales());
  }

  void _openNewSale() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: const ProductCartScreen(),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    
    if (result == true) {
      _loadSales();
    }
  }

  void _viewSaleDetails(Sale sale) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _SaleDetailsSheet(
            sale: sale,
            scrollController: scrollController,
            onRefund: () => _refundSale(sale),
            onPrintReceipt: () => _printReceipt(sale),
          ),
        ),
      ),
    );
  }

  void _refundSale(Sale sale) {
    HapticManager.trigger(HapticType.medium);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Sale'),
        content: Text('Are you sure you want to refund sale #${sale.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ModernButton(
            text: 'Refund',
            type: ModernButtonType.primary,
            backgroundColor: AppColors.kWarning,
            size: ModernButtonSize.small,
            onPressed: () {
              Navigator.pop(context);
              context.read<SalesBloc>().add(LoadSales());
              HapticManager.trigger(HapticType.success);
            },
          ),
        ],
      ),
    );
  }

  void _printReceipt(Sale sale) {
    HapticManager.trigger(HapticType.light);
    // Implement print receipt functionality
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    if (query.isEmpty) {
      _loadSales();
    } else {
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernAppBar(),
          _buildQuickStats(),
          _buildSearchAndFilters(),
          _buildSalesList(),
        ],
      ),
      floatingActionButton: FloatingActionBubble(
        backgroundColor: ThemeManager().currentBusinessColors.primary,
        items: [
          FloatingActionItem(
            icon: Icons.add_shopping_cart,
            onTap: _openNewSale,
            backgroundColor: ThemeManager().currentBusinessColors.primary,
            tooltip: 'New Sale',
          ),
          FloatingActionItem(
            icon: Icons.qr_code_scanner,
            onTap: _scanProduct,
            backgroundColor: ThemeManager().currentBusinessColors.secondary,
            tooltip: 'Scan Product',
          ),
          FloatingActionItem(
            icon: Icons.receipt_long,
            onTap: _viewRecentSales,
            backgroundColor: ThemeManager().currentBusinessColors.success,
            tooltip: 'Recent Sales',
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildModernAppBar() {
    final businessColors = ThemeManager().currentBusinessColors;
    
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: businessColors.primary,
      actions: [
        IconButton(
          onPressed: _showSalesReports,
          icon: const Icon(Icons.analytics, color: Colors.white),
          tooltip: 'Sales Reports',
        ),
        IconButton(
          onPressed: _showFilterOptions,
          icon: const Icon(Icons.filter_list, color: Colors.white),
          tooltip: 'Filter',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Sales',
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
                          Icons.point_of_sale,
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
                              'Sales Management',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Process sales and manage transactions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
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

  Widget _buildQuickStats() {
    return SliverToBoxAdapter(
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          if (state is SalesLoaded) {
            final todaySales = state.sales.where((sale) {
              final today = DateTime.now();
              return sale.soldAt.year == today.year &&
                     sale.soldAt.month == today.month &&
                     sale.soldAt.day == today.day;
            }).toList();
            
            final todayTotal = todaySales.fold<double>(
              0.0, (sum, sale) => sum + (sale.totalAmount ?? 0.0)
            );
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: AdvancedStaggeredGrid(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                children: [
                  _buildStatCard(
                    'Today\'s Sales',
                    '${todaySales.length}',
                    Icons.today,
                    ThemeManager().currentBusinessColors.primary,
                    0,
                  ),
                  _buildStatCard(
                    'Today\'s Revenue',
                    CurrencyFmt.format(context, todayTotal),
                    Icons.attach_money,
                    ThemeManager().currentBusinessColors.success,
                    100,
                  ),
                ],
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, int delay) {
    return AdvancedFeatureCard(
      type: FeatureCardType.primary,
      title: title,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      accentColor: color,
      animationDelay: delay,
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search sales by ID, customer, amount...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Completed', 'completed'),
                  _buildFilterChip('Pending', 'pending'),
                  _buildFilterChip('Refunded', 'refunded'),
                  _buildFilterChip('Today', 'today'),
                  _buildFilterChip('This Week', 'week'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    final businessColors = ThemeManager().currentBusinessColors;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
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

  Widget _buildSalesList() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        if (state is SalesLoading) {
          return _buildLoadingState();
        }
        
        if (state is SalesError) {
          return SliverFillRemaining(
            child: UniversalPlaceholder.error(
              message: state.message,
              onRetry: _loadSales,
            ),
          );
        }
        
        if (state is SalesLoaded) {
          final sales = state.sales;
          
          if (sales.isEmpty) {
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
                      feature: 'sales',
                      onCreate: _openNewSale,
                    ),
            );
          }
          
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdvancedStaggeredList(
                children: sales.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sale = entry.value;
                  return _ModernSaleCard(
                    sale: sale,
                    animationDelay: index * 30,
                    onTap: () => _viewSaleDetails(sale),
                    onRefund: () => _refundSale(sale),
                    onPrint: () => _printReceipt(sale),
                  );
                }).toList(),
                animationType: AnimationType.slideUp,
                enablePullToRefresh: true,
                onRefresh: () async {
                  _loadSales();
                },
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          );
        }
        
        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  width: 80,
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

  void _scanProduct() {
    HapticManager.trigger(HapticType.medium);
    // Implement product scanning for quick sale
  }

  void _viewRecentSales() {
    HapticManager.trigger(HapticType.light);
    // Show recent sales quick view
  }

  void _showSalesReports() {
    HapticManager.trigger(HapticType.light);
    // Navigate to sales reports
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort & Filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sort By:'),
            const SizedBox(height: 8),
            ...[
              ('Date (Newest)', 'date'),
              ('Amount (Highest)', 'amount'),
              ('Customer', 'customer'),
              ('Status', 'status'),
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
}

class _ModernSaleCard extends StatelessWidget {
  final Sale sale;
  final int animationDelay;
  final VoidCallback onTap;
  final VoidCallback onRefund;
  final VoidCallback onPrint;

  const _ModernSaleCard({
    required this.sale,
    required this.animationDelay,
    required this.onTap,
    required this.onRefund,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final businessColors = ThemeManager().currentBusinessColors;
    final statusColor = _getStatusColor(sale.invoiceStatus?.status);
    
    return AdvancedFeatureCard(
      type: FeatureCardType.detailed,
      title: 'Sale #${sale.id}',
      subtitle: _formatDate(sale.soldAt),
      description: 'Customer #${sale.customerId ?? 0}',
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.2),
          ),
        ),
        child: Icon(
          _getStatusIcon(sale.invoiceStatus?.status),
          color: statusColor,
          size: 24,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            CurrencyFmt.format(context, sale.totalAmount ?? 0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: businessColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(sale.invoiceStatus?.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      badges: [
        if (sale.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${sale.items.length} items',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
      ],
      actions: [
        FeatureCardAction.view,
        if (sale.invoiceStatus?.isPaid == true) ...[
          FeatureCardAction.edit, // For print receipt
          FeatureCardAction.delete, // For refund
        ],
      ],
      onTap: onTap,
      onActionTap: (action) {
        switch (action) {
          case FeatureCardAction.view:
            onTap();
            break;
          case FeatureCardAction.edit: // Print
            onPrint();
            break;
          case FeatureCardAction.delete: // Refund
            onRefund();
            break;
          default:
            break;
        }
      },
      animationDelay: animationDelay,
      accentColor: statusColor,
      metadata: {
        'Customer': 'Customer #${sale.customerId ?? 0}',
        'Items': '${sale.items.length} products',
        'Discount': CurrencyFmt.format(context, sale.discount),
        'Time': _formatTime(sale.soldAt),
      },
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppColors.kWarning;
    final lower = status.toLowerCase();
    if (lower.contains('completed') || lower.contains('paid')) return AppColors.kSuccess;
    if (lower.contains('pending') || lower.contains('draft')) return AppColors.kWarning;
    if (lower.contains('cancelled') || lower.contains('refunded')) return AppColors.kError;
    return AppColors.kInfo;
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.help_outline;
    final lower = status.toLowerCase();
    if (lower.contains('completed') || lower.contains('paid')) return Icons.check_circle;
    if (lower.contains('pending') || lower.contains('draft')) return Icons.access_time;
    if (lower.contains('cancelled')) return Icons.cancel;
    if (lower.contains('refunded')) return Icons.undo;
    return Icons.help_outline;
  }

  String _getStatusText(String? status) {
    return status ?? 'Unknown';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final saleDate = DateTime(date.year, date.month, date.day);
    
    if (saleDate == today) {
      return 'Today';
    } else if (saleDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SaleDetailsSheet extends StatelessWidget {
  final Sale sale;
  final ScrollController scrollController;
  final VoidCallback onRefund;
  final VoidCallback onPrintReceipt;

  const _SaleDetailsSheet({
    required this.sale,
    required this.scrollController,
    required this.onRefund,
    required this.onPrintReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final businessColors = ThemeManager().currentBusinessColors;
    
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Sale Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: businessColors.gradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sale #${sale.id}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(sale.soldAt)} at ${_formatTime(sale.soldAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(sale.invoiceStatus?.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(sale.invoiceStatus?.status),
                  style: TextStyle(
                    color: _getStatusColor(sale.invoiceStatus?.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Customer Info
          if (sale.customerId != null) ...[
            _buildSectionTitle('Customer Information'),
            AdvancedFeatureCard(
              type: FeatureCardType.compact,
              title: 'Customer #${sale.customerId}',
              subtitle: 'View in detail view',
              leading: CircleAvatar(
                backgroundColor: businessColors.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: businessColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Items
          _buildSectionTitle('Items (${sale.items.length})'),
          ...sale.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdvancedFeatureCard(
                type: FeatureCardType.compact,
                title: 'Product #${item.productId}',
                subtitle: '${item.quantitySold} x ${CurrencyFmt.format(context, item.salePricePerQuantity)}',
                trailing: Text(
                  CurrencyFmt.format(context, item.totalSalePrice),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: businessColors.success,
                  ),
                ),
                animationDelay: index * 50,
              ),
            );
          }).toList(),
          
          const SizedBox(height: 20),
          
          // Summary
          _buildSectionTitle('Payment Summary'),
          AdvancedFeatureCard(
            type: FeatureCardType.primary,
            title: 'Total Amount',
            trailing: Text(
              CurrencyFmt.format(context, sale.totalAmount ?? 0),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: businessColors.success,
              ),
            ),
            accentColor: businessColors.success,
            metadata: {
              'Subtotal': CurrencyFmt.format(context, (sale.totalAmount ?? 0)),
              'Discount': CurrencyFmt.format(context, sale.discount),
              'Payment Date': _formatDate(sale.soldAt),
              'Status': _getStatusText(sale.invoiceStatus?.status),
            },
          ),
          
          const SizedBox(height: 30),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Print Receipt',
                  icon: Icons.print,
                  type: ModernButtonType.outline,
                  onPressed: () {
                    Navigator.pop(context);
                    onPrintReceipt();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernButton(
                  text: sale.invoiceStatus?.isPaid == true ? 'Refund' : 'Cancel',
                  icon: sale.invoiceStatus?.isPaid == true ? Icons.undo : Icons.cancel,
                  type: ModernButtonType.primary,
                  backgroundColor: AppColors.kWarning,
                  onPressed: () {
                    Navigator.pop(context);
                    onRefund();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String? status) {
    if (status == null) return AppColors.kWarning;
    final lower = status.toLowerCase();
    if (lower.contains('completed') || lower.contains('paid')) return AppColors.kSuccess;
    if (lower.contains('pending') || lower.contains('draft')) return AppColors.kWarning;
    if (lower.contains('cancelled') || lower.contains('refunded')) return AppColors.kError;
    return AppColors.kInfo;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final saleDate = DateTime(date.year, date.month, date.day);
    
    if (saleDate == today) {
      return 'Today';
    } else if (saleDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getStatusText(String? status) {
    return status ?? 'Unknown';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}