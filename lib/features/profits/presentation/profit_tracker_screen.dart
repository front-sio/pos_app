import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/profits/services/profit_services.dart';
import 'package:sales_app/widgets/responsive_grid.dart';
import 'package:sales_app/widgets/stats_card.dart';
import 'package:sales_app/widgets/animated_card.dart';
import 'package:sales_app/features/profits/bloc/profit_bloc.dart';
import 'package:sales_app/features/profits/bloc/profit_event.dart';
import 'package:sales_app/features/profits/bloc/profit_state.dart';
import 'package:intl/intl.dart';

class ProfitTrackerScreen extends StatefulWidget {
  const ProfitTrackerScreen({Key? key}) : super(key: key);

  @override
  State<ProfitTrackerScreen> createState() => _ProfitTrackerScreenState();
}

class _ProfitTrackerScreenState extends State<ProfitTrackerScreen> {
  String _selectedPeriod = 'This Month';
  String _selectedView = 'Daily';

  @override
  void initState() {
    super.initState();
    // Kick off load once BLoC is available in tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfitBloc>().add(LoadProfit(period: _selectedPeriod, view: _selectedView));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfitBloc(service: ProfitService()),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              elevation: 0,
              floating: true,
              snap: true,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit Tracker',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextPrimary,
                            ),
                      ),
                      Text(
                        'Monitor your business performance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.kTextSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSizes.largePadding),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {},
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'settings', child: Text('Settings')),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPeriodSelector(),
                      _buildViewSelector(),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: BlocBuilder<ProfitBloc, ProfitState>(
            builder: (context, state) {
              if (state is ProfitLoading || state is ProfitInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProfitError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.padding * 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.kError, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.read<ProfitBloc>().add(RefreshProfit()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final loaded = state as ProfitLoaded;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSummaryCards(loaded),
                  _buildChartSection(loaded),
                  _buildTransactionsList(loaded),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return OutlinedButton.icon(
      onPressed: () async {
        final selectedValue = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(100, 100, 100, 100),
          items: [
            'Today',
            'This Week',
            'This Month',
            'Last 3 Months',
            'Custom Range',
          ].map((String value) {
            return PopupMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
        if (selectedValue != null) {
          setState(() => _selectedPeriod = selectedValue);
          context.read<ProfitBloc>().add(ChangePeriod(selectedValue));
        }
      },
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(_selectedPeriod),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.kPrimary,
        side: BorderSide(color: AppColors.kPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
      ),
    );
  }

  Widget _buildViewSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(value: 'Daily', label: Text('Daily')),
        ButtonSegment<String>(value: 'Weekly', label: Text('Weekly')),
        ButtonSegment<String>(value: 'Monthly', label: Text('Monthly')),
      ],
      selected: {_selectedView},
      onSelectionChanged: (Set<String> selected) {
        setState(() => _selectedView = selected.first);
        context.read<ProfitBloc>().add(ChangeView(selected.first));
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.kPrimary,
        selectedForegroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCards(ProfitLoaded data) {
    final fmt = NumberFormat.compactCurrency(symbol: '\$');
    final revenue = fmt.format(data.summary.revenue);
    final gross = fmt.format(data.summary.grossProfit);
    final net = fmt.format(data.summary.netProfit);
    final margin = '${data.summary.profitMargin.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: ResponsiveGrid(
        spacing: AppSizes.padding,
        runSpacing: AppSizes.padding,
        children: [
          AnimatedCard(
            child: StatCard(
              title: 'Gross Profit',
              value: gross,
              subtitle: '${data.summary.orders} orders',
              icon: Icons.trending_up,
              color: AppColors.kSuccess,
            ),
          ),
          AnimatedCard(
            child: StatCard(
              title: 'Net Profit',
              value: net,
              subtitle: 'After costs',
              icon: Icons.account_balance_wallet,
              color: AppColors.kPrimary,
            ),
          ),
          AnimatedCard(
            child: StatCard(
              title: 'Profit Margin',
              value: margin,
              subtitle: 'Net / Revenue',
              icon: Icons.pie_chart,
              color: AppColors.kSecondary,
            ),
          ),
          AnimatedCard(
            child: StatCard(
              title: 'Revenue',
              value: revenue,
              subtitle: 'Total',
              icon: Icons.payments,
              color: AppColors.kWarning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(ProfitLoaded data) {
    final points = data.timeline;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profit Trend', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'download', child: Text('Download Report')),
                      PopupMenuItem(value: 'share', child: Text('Share')),
                      PopupMenuItem(value: 'print', child: Text('Print')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.padding),
              SizedBox(
                height: 220,
                child: points.isEmpty
                    ? const Center(child: Text('No data'))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: points.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final p = points[i];
                          final v = p.netProfit;
                          final max = (points.map((e) => e.netProfit).fold<double>(0, (a, b) => a > b ? a : b)).clamp(1, double.infinity);
                          final h = (v / max) * 180;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 16,
                                height: h,
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(p.label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(ProfitLoaded data) {
    final txs = data.transactions;
    final fmtMoney = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement view all
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View All'),
                  ),
                ],
              ),
            ),
            if (txs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSizes.padding),
                child: Text('No transactions'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: txs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = txs[index];
                  final positive = t.netProfit >= 0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (positive ? AppColors.kSuccess : AppColors.kError).withValues(alpha: 0.1),
                      child: Icon(positive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: positive ? AppColors.kSuccess : AppColors.kError),
                    ),
                    title: Text('Sale #${t.id} • ${DateFormat.yMMMd().format(t.soldAt)}'),
                    subtitle: Text('Revenue ${fmtMoney.format(t.totalAmount)}'),
                    trailing: Text(
                      '${positive ? '+' : ''}${fmtMoney.format(t.netProfit)}',
                      style: TextStyle(
                        color: positive ? AppColors.kSuccess : AppColors.kError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}