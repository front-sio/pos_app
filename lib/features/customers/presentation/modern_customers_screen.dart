import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/advanced_feature_card.dart';
import '../../../widgets/universal_placeholder.dart';
import '../../../widgets/advanced_animations.dart';
import '../../../widgets/micro_interactions.dart';
import '../../../widgets/modern_button.dart';
import '../../../theme/theme_manager.dart';
import '../../../constants/colors.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../data/customer_model.dart';
import 'customer_overlay_screen.dart';

class ModernCustomersScreen extends StatefulWidget {
  const ModernCustomersScreen({Key? key}) : super(key: key);

  @override
  State<ModernCustomersScreen> createState() => _ModernCustomersScreenState();
}

class _ModernCustomersScreenState extends State<ModernCustomersScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCustomers() {
    context.read<CustomerBloc>().add(FetchCustomers());
  }

  void _openCustomerForm(Customer? customer) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: BlocProvider.value(
            value: context.read<CustomerBloc>(),
            child: CustomerOverlayScreen(
              customer: customer,
              mode: customer == null 
                  ? CustomerOverlayMode.create 
                  : CustomerOverlayMode.edit,
              onSaved: () {
                Navigator.pop(context);
                _loadCustomers();
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteCustomer(Customer customer) {
    HapticManager.trigger(HapticType.medium);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
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
              context.read<CustomerBloc>().add(DeleteCustomerEvent(customer.id));
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
      _loadCustomers();
    } else {
      context.read<CustomerBloc>().add(SearchCustomers(query));
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
          _buildSearchSection(),
          _buildCustomersList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCustomerForm(null),
        backgroundColor: ThemeManager().currentBusinessColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  SliverAppBar _buildModernAppBar() {
    final businessColors = ThemeManager().currentBusinessColors;
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: businessColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Customers',
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
                          Icons.people,
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
                              'Customers',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            BlocBuilder<CustomerBloc, CustomerState>(
                              builder: (context, state) {
                                final count = state is CustomersLoaded 
                                    ? state.customers.length 
                                    : 0;
                                return Text(
                                  '$count total customers',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
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

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Search customers...',
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
      ),
    );
  }

  Widget _buildCustomersList() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomersLoading) {
          return _buildLoadingState();
        }
        
        if (state is CustomersError) {
          return SliverFillRemaining(
            child: UniversalPlaceholder.error(
              message: state.message,
              onRetry: _loadCustomers,
            ),
          );
        }
        
        if (state is CustomersLoaded) {
          final customers = state.customers;
          
          if (customers.isEmpty) {
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
                      feature: 'customers',
                      onCreate: () => _openCustomerForm(null),
                    ),
            );
          }
          
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdvancedStaggeredList(
                children: customers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final customer = entry.value;
                  return _ModernCustomerCard(
                    customer: customer,
                    animationDelay: index * 50,
                    onTap: () => _openCustomerForm(customer),
                    onEdit: () => _openCustomerForm(customer),
                    onDelete: () => _deleteCustomer(customer),
                  );
                }).toList(),
                animationType: AnimationType.slideUp,
                enablePullToRefresh: true,
                onRefresh: () async {
                  _loadCustomers();
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
                leading: const CircleAvatar(),
                trailing: Container(width: 60, height: 20, color: Colors.grey.shade300),
                isLoading: true,
                animationDelay: index * 100,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ModernCustomerCard extends StatelessWidget {
  final Customer customer;
  final int animationDelay;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ModernCustomerCard({
    required this.customer,
    required this.animationDelay,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final businessColors = ThemeManager().currentBusinessColors;
    
    return AdvancedFeatureCard(
      type: FeatureCardType.list,
      title: customer.name,
      subtitle: customer.email ?? customer.phone ?? 'No contact info',
      leading: CircleAvatar(
        backgroundColor: businessColors.primary.withOpacity(0.1),
        child: Icon(
          Icons.person,
          color: businessColors.primary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
      metadata: {
        if (customer.phone != null) 'Phone': customer.phone!,
        if (customer.email != null) 'Email': customer.email!,
      },
    );
  }
}