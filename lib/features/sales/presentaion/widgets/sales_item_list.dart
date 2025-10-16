import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/sales/data/sale_item.dart';


class SaleItemList extends StatelessWidget {
  final List<SaleItem> items;

  const SaleItemList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text('Product #${item.productId}'),
          subtitle: Text(
            '${item.quantitySold} x \$${item.salePricePerQuantity.toStringAsFixed(2)}',
          ),
          trailing: Text(
            '\$${item.totalSalePrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.kPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}