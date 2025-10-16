import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/utils/responsive.dart';

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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 56),
                    const SizedBox(height: 12),
                    Text('Failed to load customers', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(state.message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<CustomerBloc>().add(FetchCustomers()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is CustomersLoaded) {
          final customers = state.customers;
          if (customers.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: cs.onSurface.withOpacity(0.35)),
                    const SizedBox(height: 12),
                    Text(
                      _isSearching ? 'No customers found' : 'No customers yet',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSearching ? 'Try another search' : 'Add your first customer to get started',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (!_isSearching) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openOverlay(null, CustomerOverlayMode.create),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add Customer'),
                      ),
                    ]
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
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: _hp(context)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final c = customers[i];
            return AnimatedContainer(
              duration: Duration(milliseconds: 120 + i * 30),
              margin: const EdgeInsets.only(bottom: 10),
              child: _card(c, true),
            );
          },
          childCount: customers.length,
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
                      child: Text(
                        c.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  ],
                ),
        ),
      ),
    );
  }
}