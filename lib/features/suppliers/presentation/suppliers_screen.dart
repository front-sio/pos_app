import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/utils/responsive.dart';
import 'package:sales_app/constants/sizes.dart';

import 'package:sales_app/features/suppliers/bloc/supplier_bloc.dart' as sup_bloc;
import 'package:sales_app/features/suppliers/bloc/supplier_event.dart' as sup_event;
import 'package:sales_app/features/suppliers/bloc/supplier_state.dart' as sup_state;

import 'package:sales_app/features/suppliers/data/supplier_model.dart';
import 'package:sales_app/features/suppliers/presentation/supplier_overlay_screen.dart';

class SuppliersScreen extends StatefulWidget {
  final Future<void> Function(Supplier? supplier, SupplierOverlayMode mode)? onOpenOverlay;

  const SuppliersScreen({super.key, this.onOpenOverlay});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> with TickerProviderStateMixin {
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

    final state = context.read<sup_bloc.SupplierBloc>().state;
    if (state is! sup_state.SuppliersLoaded && state is! sup_state.SuppliersLoading) {
      context.read<sup_bloc.SupplierBloc>().add(sup_event.FetchSuppliersPage(1, _limit));
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

    // Stop if near end and no more pages
    final st = context.read<sup_bloc.SupplierBloc>().state;
    if (st is sup_state.SuppliersLoaded && !st.hasMore) return;

    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _page++;
      context.read<sup_bloc.SupplierBloc>().add(sup_event.FetchSuppliersPage(_page, _limit));
    }
  }

  double _hp(BuildContext ctx) {
    if (Responsive.isMobile(ctx)) return 12;
    if (Responsive.isTablet(ctx)) return 20;
    return 24;
  }

  void _openOverlay(Supplier? s, SupplierOverlayMode mode) async {
    if (widget.onOpenOverlay != null) {
      await widget.onOpenOverlay!(s, mode);
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
          height: MediaQuery.of(context).size.height * 0.9,
          child: BlocProvider.value(
            value: context.read<sup_bloc.SupplierBloc>(),
            child: SupplierOverlayScreen(
              supplier: s,
              mode: mode,
              onSaved: () => Navigator.of(context).pop(),
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  // Map raw technical errors to user-friendly messages
  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    final codeMatch = RegExp(r'http\s+(\d{3})', caseSensitive: false).firstMatch(raw);
    final code = codeMatch != null ? int.tryParse(codeMatch.group(1)!) : null;

    if (lower.contains('socketexception') || lower.contains('failed host lookup') || lower.contains('network')) {
      return 'Network connection problem. Please check your internet and try again.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    if (lower.contains('handshakeexception') || lower.contains('certificate') || lower.contains('tls')) {
      return 'Secure connection could not be established. Please try again later.';
    }
    if (code != null) {
      if (code == 401) return 'Your session has expired. Please sign in again.';
      if (code == 403) return 'You do not have permission to perform this action.';
      if (code == 404) return 'We could not find the requested resource.';
      if (code >= 500) return 'Server error. Please try again in a moment.';
    }
    if (lower.contains('formatexception') || lower.contains('unexpected character')) {
      return 'Received unexpected data. Please try again.';
    }
    return 'Something went wrong while loading suppliers. Please try again.';
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
                    'Suppliers',
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
        onPressed: () => _openOverlay(null, SupplierOverlayMode.create),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add Supplier'),
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
              hintText: 'Search suppliers...',
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: _isSearching ? cs.primary : cs.onSurface.withOpacity(0.6)),
              border: InputBorder.none,
            ),
            onChanged: (q) {
              setState(() => _isSearching = q.isNotEmpty);
              context.read<sup_bloc.SupplierBloc>().add(sup_event.SearchSuppliers(q));
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

    return BlocBuilder<sup_bloc.SupplierBloc, sup_state.SupplierState>(
      builder: (context, state) {
        if (state is sup_state.SuppliersLoading) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: cs.primary)),
          );
        }

        if (state is sup_state.SuppliersError) {
          final userMsg = _friendlyError(state.message);
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: cs.primary, size: 56),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load suppliers',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userMsg,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.read<sup_bloc.SupplierBloc>().add(sup_event.FetchSuppliers()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.read<sup_bloc.SupplierBloc>().add(sup_event.FetchSuppliersPage(1, _limit)),
                          icon: const Icon(Icons.sync),
                          label: const Text('Reload'),
                        ),
                      ],
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: const Text('Technical details (debug)'),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              state.message,
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.8)),
                            ),
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

        if (state is sup_state.SuppliersLoaded) {
          final suppliers = state.suppliers;
          if (suppliers.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_mall_directory_outlined, size: 64, color: cs.onSurface.withOpacity(0.35)),
                    const SizedBox(height: 12),
                    Text(
                      _isSearching ? 'No suppliers found' : 'No suppliers yet',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSearching ? 'Try another search' : 'Add your first supplier to get started',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (!_isSearching) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openOverlay(null, SupplierOverlayMode.create),
                        icon: const Icon(Icons.add_business_outlined),
                        label: const Text('Add Supplier'),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }

          return Responsive.isMobile(context) ? _mobileList(suppliers) : _gridList(suppliers);
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _mobileList(List<Supplier> suppliers) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: _hp(context)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final s = suppliers[i];
            return AnimatedContainer(
              duration: Duration(milliseconds: 120 + i * 30),
              margin: const EdgeInsets.only(bottom: 10),
              child: _card(s, true),
            );
          },
          childCount: suppliers.length,
        ),
      ),
    );
  }

  Widget _gridList(List<Supplier> suppliers) {
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
            final s = suppliers[i];
            return AnimatedContainer(
              duration: Duration(milliseconds: 120 + i * 30),
              child: _card(s, false),
            );
          },
          childCount: suppliers.length,
        ),
      ),
    );
  }

  Widget _card(Supplier s, bool compact) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final menu = PopupMenuButton<String>(
      onSelected: (v) {
        switch (v) {
          case 'view':
            _openOverlay(s, SupplierOverlayMode.view);
            break;
          case 'edit':
            _openOverlay(s, SupplierOverlayMode.edit);
            break;
          case 'delete':
            _openOverlay(s, SupplierOverlayMode.deleteConfirm);
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
        onTap: () => _openOverlay(s, SupplierOverlayMode.view),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: compact
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primary.withOpacity(0.1),
                      child: Icon(Icons.store, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(s.email ?? 'No email', style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(s.phone ?? 'No phone', style: theme.textTheme.bodySmall),
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
                          child: Icon(Icons.store, color: cs.primary),
                        ),
                        const Spacer(),
                        menu,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(s.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(s.email ?? 'No email', style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(s.phone ?? 'No phone', style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text(s.address ?? 'No address', style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
        ),
      ),
    );
  }
}