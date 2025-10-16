import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSizes.padding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardSummary(context),
                    const SizedBox(height: AppSizes.padding * 2),
                    _buildSectionHeader(context, "Quick Actions"),
                    const SizedBox(height: AppSizes.padding),
                    // _buildQuickActions(context),
                    // const SizedBox(height: AppSizes.padding * 2),
                    _buildSectionHeader(context, "Recent Activity"),
                    const SizedBox(height: AppSizes.padding),
                    _buildRecentActivity(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text("New Sale"),
        backgroundColor: AppColors.kPrimary,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
        if (title == "Recent Activity")
          TextButton(
            onPressed: () {},
            child: Text(
              "View All",
              style: TextStyle(color: AppColors.kPrimary),
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardSummary(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isSmallScreen ? 2 : 3,
      crossAxisSpacing: AppSizes.padding,
      mainAxisSpacing: AppSizes.padding,
      childAspectRatio: isSmallScreen ? 1.5 : 1.8,
      children: [
        _buildSummaryCard(
          context: context,
          title: "Today's Sales",
          value: "\$2,456",
          icon: Icons.trending_up,
          color: AppColors.kPrimary,
          trend: "+15%",
          isPositive: true,
        ),
        _buildSummaryCard(
          context: context,
          title: "Orders",
          value: "45",
          icon: Icons.shopping_cart,
          color: AppColors.kSecondary,
          trend: "+5%",
          isPositive: false,
        ),
        if (!isSmallScreen)
          _buildSummaryCard(
            context: context,
            title: "Profit",
            value: "\$890",
            icon: Icons.account_balance_wallet,
            color: AppColors.kSuccess,
            trend: "+8%",
            isPositive: true,
          ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.kSuccess : AppColors.kError).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? AppColors.kSuccess : AppColors.kError,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          color: isPositive ? AppColors.kSuccess : AppColors.kError,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.kText,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.kTextSecondary,
                  ),
            ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isMediumScreen = MediaQuery.of(context).size.width < 1024;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : (isMediumScreen ? 3 : 4),
        mainAxisSpacing: AppSizes.padding,
        crossAxisSpacing: AppSizes.padding,
        childAspectRatio: isSmallScreen ? 1.2 : 1.4,
      ),
      itemCount: quickActions.length,
      itemBuilder: (context, index) {
        final action = quickActions[index];
        return _buildActionCard(
          context: context,
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['iconColor'] as Color,
          onTap: () => Navigator.pushNamed(context, action['route'] as String),
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.kText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Column(
        children: List.generate(
          5,
          (index) => _buildActivityItem(context, index),
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: index == 4 ? 0 : 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shopping_cart,
            color: AppColors.kPrimary,
            size: 20,
          ),
        ),
        title: Text(
          'New sale completed',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Text(
          '2 minutes ago',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '\$99.99',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.kSuccess,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

// Quick actions data
final List<Map<String, dynamic>> quickActions = [
  {
    "label": "Add Product",
    "icon": Icons.add_box,
    "iconColor": AppColors.kPrimary,
    "route": "/products/add",
  },
  {
    "label": "Add Stock",
    "icon": Icons.inventory_2,
    "iconColor": AppColors.kSecondary,
    "route": "/stock/add",
  },
  {
    "label": "Record Purchase",
    "icon": Icons.shopping_cart_checkout,
    "iconColor": AppColors.kWarning,
    "route": "/purchases/add",
  },
  {
    "label": "Record Sale",
    "icon": Icons.point_of_sale,
    "iconColor": AppColors.kSuccess,
    "route": "/sales/add",
  },
  {
    "label": "View Profit",
    "icon": Icons.account_balance_wallet,
    "iconColor": AppColors.kInfo,
    "route": "/profit-tracker",
  },
];