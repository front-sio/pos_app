import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/utils/responsive.dart';
import 'package:sales_app/widgets/error_placeholder.dart';
import 'package:sales_app/widgets/advanced_feature_card.dart';
import 'package:sales_app/widgets/universal_placeholder.dart';
import 'package:sales_app/widgets/advanced_animations.dart';
import 'package:sales_app/widgets/micro_interactions.dart';
import 'package:sales_app/widgets/modern_button.dart';
import 'package:sales_app/theme/theme_manager.dart';

import 'package:sales_app/features/customers/bloc/customer_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';
import 'package:sales_app/features/customers/bloc/customer_state.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';
import 'package:sales_app/features/customers/presentation/customer_overlay_screen.dart';

class CustomersScreen extends StatefulWidget {
  final Future<void> Function(Customer? customer, CustomerOverlayMode mode)? onOpenOverlay;

  const CustomersScreen({super.key, this.onOpenOverlay});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _page = 1;
  static const int _limit = 20;
  bool _isSearching = false;

  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);

    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();

    final state = context.read<CustomerBloc>().state;
    if (state is! CustomersLoaded && state is! CustomersLoading) {
      context.read<CustomerBloc>().add(FetchCustomersPage(1, _limit));
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _page++;
      context.read<CustomerBloc>().add(FetchCustomersPage(_page, _limit));
    }
  }

  double _hp(BuildContext ctx) {
    if (Responsive.isMobile(ctx)) return 12;
    if (Responsive.isTablet(ctx)) return 20;
    return 24;
  }

  void _openOverlay(Customer? c, CustomerOverlayMode mode) async {
    if (widget.onOpenOverlay != null) {
      await widget.onOpenOverlay!(c, mode);
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: BlocProvider.value(
            value: context.read<CustomerBloc>(),
            child: CustomerOverlayScreen(
              customer: c,
              mode: mode,
              onSaved: () => Navigator.of(context).pop(),
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                expandedHeight: Responsive.isMobile(context) ? 100 : 70,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Customers',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(
                    left: _hp(context),
                    bottom: 16,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined),
                    onPressed: () {},
                    tooltip: 'Filter',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: _searchBar(context),
              ),
              _list(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openOverlay(null, CustomerOverlayMode.create),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _hp(context), vertical: 8),
      child: Card(
        elevation: theme.cardTheme.elevation ?? 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              // ignore: deprecated_member_use
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: _isSearching ? cs.primary : cs.onSurface.withOpacity(0.6)),
              border: InputBorder.none,
            ),
            onChanged: (q) {
              setState(() => _isSearching = q.isNotEmpty);
              context.read<CustomerBloc>().add(SearchCustomers(q));
            },
            onSubmitted: (_) => HapticFeedback.lightImpact(),
          ),
        ),
      ),
    );
  }

  Widget _list() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomersLoading) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: cs.primary)),
          );
        }

        if (state is CustomersError) {
          return SliverFillRemaining(
            child: ErrorPlaceholder(
              onRetry: () => context.read<CustomerBloc>().add(FetchCustomersPage(_page, _limit)),
            ),
          );
        }

        if (state is CustomersLoaded) {
          final customers = state.customers;
          if (customers.isEmpty) {
            return SliverFillRemaining(
              child: _isSearching
                  ? UniversalPlaceholder.noResults(
                      searchTerm: _searchCtrl.text,
                      onClearSearch: () {
                        _searchCtrl.clear();
                        setState(() => _isSearching = false);
                        context.read<CustomerBloc>().add(FetchCustomersPage(1, _limit));
                      },
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: _hp(context)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UniversalPlaceholder.empty(
                            feature: 'customers',
                            onCreate: () => _openOverlay(null, CustomerOverlayMode.create),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openOverlay(null, CustomerOverlayMode.create),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add Customer'),
                          ),
                        ],
                      ),
                    ),
            );
          }

          return Responsive.isMobile(context) ? _mobileList(customers) : _gridList(customers);
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _mobileList(List<Customer> customers) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _hp(context)),
        child: AdvancedStaggeredList(
          children: customers.asMap().entries.map((entry) {
            final index = entry.key;
            final customer = entry.value;
            return _ModernCustomerCard(
              customer: customer,
              animationDelay: index * 50,
              onTap: () => _openOverlay(customer, CustomerOverlayMode.edit),
              onEdit: () => _openOverlay(customer, CustomerOverlayMode.edit),
              onDelete: () => _deleteCustomer(customer),
            );
          }).toList(),
          animationType: AnimationType.slideUp,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }

  Widget _gridList(List<Customer> customers) {
    return SliverPadding(
      padding: EdgeInsets.all(_hp(context)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isTablet(context) ? 2 : 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final c = customers[i];
            return AnimatedContainer(
              duration: Duration(milliseconds: 120 + i * 30),
              child: _card(c, false),
            );
          },
          childCount: customers.length,
        ),
      ),
    );
  }

  Widget _card(Customer c, bool compact) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final menu = PopupMenuButton<String>(
      onSelected: (v) {
        switch (v) {
          case 'view':
            _openOverlay(c, CustomerOverlayMode.view);
            break;
          case 'edit':
            _openOverlay(c, CustomerOverlayMode.edit);
            break;
          case 'delete':
            _openOverlay(c, CustomerOverlayMode.deleteConfirm);
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
      color: theme.cardColor,
      elevation: theme.cardTheme.elevation ?? 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openOverlay(c, CustomerOverlayMode.view),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: compact
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primary.withOpacity(0.1),
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: TextStyle(color: cs.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (c.email != null && c.email!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 14, color: cs.onSurface.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    c.email!,
                                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (c.phone != null && c.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 14, color: cs.onSurface.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  c.phone!,
                                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    menu,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: cs.primary.withOpacity(0.1),
                          child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: TextStyle(color: cs.primary)),
                        ),
                        const Spacer(),
                        menu,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (c.email != null && c.email!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: cs.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.email!,
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (c.phone != null && c.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: cs.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            c.phone!,
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
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
            backgroundColor: ThemeManager().currentBusinessColors.error,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (customer.totalPurchases != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: businessColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$${customer.totalPurchases?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  color: businessColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
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
      metadata: {
        if (customer.phone != null) 'Phone': customer.phone!,
        if (customer.address != null) 'Address': customer.address!,
      },
    );
  }
}