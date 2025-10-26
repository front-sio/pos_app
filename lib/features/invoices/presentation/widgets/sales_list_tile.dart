import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/sales/data/sale_item.dart';

class SaleItemList extends StatelessWidget {
  final List<SaleItem> items;
  final Map<int, String>? productNames; // Optional: provide id -> name map

  const SaleItemList({
    super.key,
    required this.items,
    this.productNames,
  });

  String _resolveName(BuildContext context, int productId) {
    if (productNames != null && productNames!.containsKey(productId)) {
      return productNames![productId]!;
    }
    final ps = context.read<ProductsBloc>().state;
    if (ps is ProductsLoaded) {
      final found = ps.products.where((p) => p.id == productId);
      if (found.isNotEmpty) return found.first.name;
    }
    return 'Product #$productId';
    }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final title = _resolveName(context, item.productId);
        return ListTile(
          title: Text(title),
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