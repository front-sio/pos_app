import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';

import 'package:sales_app/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:sales_app/features/dashboard/bloc/dashboard_event.dart';
import 'package:sales_app/features/dashboard/bloc/dashboard_state.dart';
import 'package:sales_app/features/dashboard/data/dashboard_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load once after the first frame to avoid dispatching during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<DashboardBloc>();
      final s = bloc.state;
      if (s is! DashboardLoaded && s is! DashboardLoading) {
        bloc.add(const LoadDashboard());
      }
    });
  }

  Future<void> _refresh() async {
    final bloc = context.read<DashboardBloc>()..add(const RefreshDashboard());
    // Wait for the next terminal state (Loaded or Error) to finish the indicator
    await bloc.stream.firstWhere((s) => s is DashboardLoaded || s is DashboardError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.kPrimary,
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.padding),
                sliver: SliverToBoxAdapter(
                  child: BlocBuilder<DashboardBloc, DashboardState>(
                    buildWhen: (p, n) => n is DashboardLoading || n is DashboardLoaded || n is DashboardError,
                    builder: (context, state) {
                      if (state is DashboardLoading || state is DashboardInitial) {
                        return const _LoadingBlock();
                      }
                      if (state is DashboardError) {
                        return _ErrorBlock(message: state.message);
                      }
                      final data = (state as DashboardLoaded).data;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated switch for a smooth appearance
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: _SummaryGrid(key: ValueKey(data.summary.hashCode), summary: data.summary),
                          ),
                          const SizedBox(height: AppSizes.padding * 2),
                          _SectionHeader(
                            title: 'Recent Activity',
                            trailing: TextButton(
                              onPressed: () {}, // TODO: route to full activity if needed
                              child: Text('View All', style: TextStyle(color: AppColors.kPrimary)),
                            ),
                          ),
                          const SizedBox(height: AppSizes.padding),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: _RecentActivityList(key: ValueKey(data.recent.hashCode), items: data.recent),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ Building blocks ----------------------------- */

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget trailing;
  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.kText,
                fontWeight: FontWeight.bold,
              ),
        ),
        trailing,
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardSummary summary;
  const _SummaryGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 600;

    // Give a bit more height on phones so the title can sit above and value below (no ellipsis)
    final aspect = isSmall ? 1.15 : 1.4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isSmall ? 2 : 3,
      crossAxisSpacing: AppSizes.padding,
      mainAxisSpacing: AppSizes.padding,
      childAspectRatio: aspect,
      children: [
        _SummaryCard(
          title: "Today's Sales",
          value: CurrencyFmt.format(context, summary.todaySalesTotal),
          icon: Icons.trending_up,
          color: AppColors.kPrimary,
        ),
        _SummaryCard(
          title: "Orders",
          value: '${summary.todayOrdersCount}',
          icon: Icons.shopping_cart,
          color: AppColors.kSecondary,
        ),
        if (!isSmall)
          _SummaryCard(
            title: "Estimated Profit",
            value: CurrencyFmt.format(context, summary.estimatedProfit),
            icon: Icons.account_balance_wallet,
            color: AppColors.kSuccess,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW: Icon + Title (title juu; icon pembeni yake)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.kTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // VALUE: show full amount without ellipsis
            // Use FittedBox so it scales down to fit instead of truncating
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    // no maxLines/ellipsis to allow FittedBox to keep full text
                    style: (isSmall ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium)?.copyWith(
                      color: AppColors.kText,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final List<ActivityItem> items;
  const _RecentActivityList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Center(
            child: Text('No recent activity', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.kTextSecondary)),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
      child: Column(children: List.generate(items.length, (i) => _ActivityTile(item: items[i], isLast: i == items.length - 1))),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem item;
  final bool isLast;
  const _ActivityTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = item.type == ActivityType.sale ? AppColors.kSuccess : AppColors.kPrimary;
    final icon = item.type == ActivityType.sale ? Icons.sell : Icons.receipt_long;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: isLast ? 0 : 1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item.subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(_timeAgo(item.timestamp), style: Theme.of(context).textTheme.bodySmall),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            CurrencyFmt.format(context, item.amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: item.type == ActivityType.sale ? AppColors.kSuccess : AppColors.kPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------------- Helpers --------------------------------- */

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
      _Shimmer(height: 120),
      SizedBox(height: AppSizes.padding),
      _Shimmer(height: 120),
      SizedBox(height: AppSizes.padding),
      _Shimmer(height: 240),
    ]);
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: TextStyle(color: AppColors.kError)));
  }
}

class _Shimmer extends StatelessWidget {
  final double height;
  const _Shimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
    );
  }
}

String _timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds.abs() < 10) return 'now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  return '${diff.inDays}d ago';
}