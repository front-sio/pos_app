import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';
import 'package:sales_app/widgets/weekly_weather_widget.dart';
import 'package:sales_app/widgets/modern_card.dart';
import 'package:sales_app/widgets/modern_loading.dart';
import 'package:sales_app/widgets/staggered_list_view.dart';

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
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Mobile-first app bar
              _buildMobileAppBar(context),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16,
                  vertical: 8,
                ),
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
                          // Weekly Weather Widget
                          const WeeklyWeatherWidget(),
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
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    
    // Mobile-first responsive breakpoints
    final isXSmall = width < 360;  // Very small phones
    final isSmall = width < 600;   // Normal phones
    final isMedium = width < 900;  // Tablets portrait
    final isLarge = width >= 900;  // Tablets landscape/Desktop

    final cards = [
      _ModernSummaryCard(
        title: "Today's Sales",
        value: CurrencyFmt.format(context, summary.todaySalesTotal),
        icon: Icons.trending_up,
        gradientColors: AppColors.kPrimaryGradient,
        animationDelay: 0,
      ),
      _ModernSummaryCard(
        title: "Orders",
        value: '${summary.todayOrdersCount}',
        icon: Icons.shopping_cart,
        gradientColors: AppColors.kSuccessGradient,
        animationDelay: 100,
      ),
      _ModernSummaryCard(
        title: "Expenses",
        value: CurrencyFmt.format(context, summary.todayExpensesTotal),
        icon: Icons.money_off,
        gradientColors: AppColors.kErrorGradient,
        animationDelay: 200,
      ),
      _ModernSummaryCard(
        title: "Estimated Profit",
        value: CurrencyFmt.format(context, summary.estimatedProfit),
        icon: Icons.account_balance_wallet,
        gradientColors: AppColors.kWarningGradient,
        animationDelay: 300,
      ),
    ];

    // Mobile-first grid configuration
    final crossAxisCount = isXSmall ? 1 : isSmall ? 2 : isMedium ? 3 : 4;
    final childAspectRatio = isXSmall ? 1.8 : isSmall ? 1.3 : isMedium ? 1.2 : 1.1;
    final spacing = isXSmall ? 8.0 : isSmall ? 12.0 : 16.0;

    return StaggeredGridView(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class _ModernSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final int animationDelay;

  const _ModernSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;
    final isXSmall = screenSize.width < 360;

    return ModernCard(
      type: ModernCardType.elevated,
      gradientColors: gradientColors,
      enableHoverEffect: true,
      enableParallax: true,
      animationDelay: animationDelay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isXSmall ? 8 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isXSmall ? 8 : 12),
                ),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: isXSmall ? 20 : 24,
                ),
              ),
              SizedBox(width: isXSmall ? 8 : 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Value Display
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: (isSmall 
                ? theme.textTheme.headlineSmall 
                : theme.textTheme.headlineLarge)?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Growth indicator or subtitle (placeholder)
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                "+12% from yesterday",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
      return ModernCard(
        type: ModernCardType.elevated,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.kTextSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ModernCard(
      type: ModernCardType.elevated,
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(
          items.length,
          (i) => _ModernActivityTile(
            item: items[i],
            isLast: i == items.length - 1,
            animationDelay: i * 50,
          ),
        ),
      ),
    );
  }
}

class _ModernActivityTile extends StatefulWidget {
  final ActivityItem item;
  final bool isLast;
  final int animationDelay;
  const _ModernActivityTile({
    required this.item, 
    required this.isLast,
    required this.animationDelay,
  });

  @override
  State<_ModernActivityTile> createState() => _ModernActivityTileState();
}

class _ModernActivityTileState extends State<_ModernActivityTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppSizes.mediumAnimation,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppSizes.defaultCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.item.type == ActivityType.sale 
        ? AppColors.kSuccess 
        : widget.item.type == ActivityType.expense 
            ? AppColors.kError 
            : AppColors.kPrimary;
    final icon = widget.item.type == ActivityType.sale 
        ? Icons.sell 
        : widget.item.type == ActivityType.expense 
            ? Icons.money_off 
            : Icons.receipt_long;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.kDivider.withOpacity(0.1),
                width: widget.isLast ? 0 : 1,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Handle activity item tap
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Row(
                  children: [
                    // Icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.subtitle,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.kTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _timeAgo(widget.item.timestamp),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Amount with styled background
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        CurrencyFmt.format(context, widget.item.amount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
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
}

/* --------------------------------- Helpers --------------------------------- */

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary cards skeleton
        StaggeredGridView(
          crossAxisCount: 2,
          mainAxisSpacing: AppSizes.padding,
          crossAxisSpacing: AppSizes.padding,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ModernLoading(
              type: ModernLoadingType.shimmer,
              height: 120,
              borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
            ),
            ModernLoading(
              type: ModernLoadingType.shimmer,
              height: 120,
              borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
            ),
          ],
        ),
        
        const SizedBox(height: AppSizes.padding * 2),
        
        // Weather widget skeleton
        ModernLoading(
          type: ModernLoadingType.skeleton,
          height: 160,
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        
        const SizedBox(height: AppSizes.padding * 2),
        
        // Recent activity skeleton
        ModernLoading(
          type: ModernLoadingType.skeleton,
          height: 300,
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      type: ModernCardType.outlined,
      backgroundColor: AppColors.kError.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.kError.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.kError,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.kTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 120,
            child: ElevatedButton.icon(
              onPressed: () {
                // Trigger refresh
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kError,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mobile-first app bar
Widget _buildMobileAppBar(BuildContext context) {
  return SliverAppBar(
    floating: true,
    pinned: false,
    elevation: 0,
    backgroundColor: Colors.transparent,
    expandedHeight: 120,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.kPrimaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        Icons.dashboard,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Welcome back! Here\'s your overview',
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
