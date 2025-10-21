import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';

import 'package:sales_app/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:sales_app/features/dashboard/bloc/dashboard_event.dart';
import 'package:sales_app/features/dashboard/bloc/dashboard_state.dart';
import 'package:sales_app/features/dashboard/data/dashboard_models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.kPrimary,
          onRefresh: () async => context.read<DashboardBloc>().add(const RefreshDashboard()),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.padding),
                sliver: SliverToBoxAdapter(
                  child: BlocBuilder<DashboardBloc, DashboardState>(
                    buildWhen: (p, n) => n is DashboardLoading || n is DashboardLoaded || n is DashboardError,
                    builder: (context, state) {
                      if (state is DashboardInitial) {
                        context.read<DashboardBloc>().add(const LoadDashboard());
                        return const _LoadingBlock();
                      }
                      if (state is DashboardLoading) {
                        return const _LoadingBlock();
                      }
                      if (state is DashboardError) {
                        return _ErrorBlock(message: state.message);
                      }
                      final data = (state as DashboardLoaded).data;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryGrid(summary: data.summary),
                          const SizedBox(height: AppSizes.padding * 2),
                          _SectionHeader(
                            title: 'Recent Activity',
                            trailing: TextButton(
                              onPressed: () {}, // TODO: route to full activity if needed
                              child: Text('View All', style: TextStyle(color: AppColors.kPrimary)),
                            ),
                          ),
                          const SizedBox(height: AppSizes.padding),
                          _RecentActivityList(items: data.recent),
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
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isSmall ? 2 : 3,
      crossAxisSpacing: AppSizes.padding,
      mainAxisSpacing: AppSizes.padding,
      childAspectRatio: isSmall ? 1.5 : 1.8,
      children: [
        _SummaryCard(
          title: "Today's Sales",
          value: NumberFormat.simpleCurrency().format(summary.todaySalesTotal),
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
            value: NumberFormat.simpleCurrency().format(summary.estimatedProfit),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ]),
            const Spacer(),
            Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.kText, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.kTextSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final List<ActivityItem> items;
  const _RecentActivityList({required this.items});

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
    final money = NumberFormat.simpleCurrency();

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
        trailing: Text(
          money.format(item.amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: item.type == ActivityType.sale ? AppColors.kSuccess : AppColors.kPrimary, fontWeight: FontWeight.bold),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Shimmer(height: 120),
      const SizedBox(height: AppSizes.padding),
      _Shimmer(height: 120),
      const SizedBox(height: AppSizes.padding),
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