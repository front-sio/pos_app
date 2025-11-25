import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';

class ProductSelectorSheet extends StatefulWidget {
  const ProductSelectorSheet({super.key});

  @override
  State<ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<ProductSelectorSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.padding / 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.add_shopping_cart),
                  const SizedBox(width: 8),
                  Text('Select Product', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: AppSizes.padding),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search products',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSizes.padding),
              Flexible(
                child: BlocBuilder<ProductsBloc, ProductsState>(
                  builder: (context, state) {
                    if (state is ProductsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ProductsError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.padding),
                          child: Text(state.message, textAlign: TextAlign.center),
                        ),
                      );
                    }
                    if (state is ProductsLoaded) {
                      final query = _query;
                      final list = query.isEmpty
                          ? state.products
                          : state.products.where((p) {
                              final name = p.name.toLowerCase();
                              final barcode = (p.barcode ?? '').toLowerCase();
                              final category = (p.categoryName ?? '').toLowerCase();
                              final unit = (p.unitName ?? '').toLowerCase();
                              return name.contains(query) ||
                                  barcode.contains(query) ||
                                  category.contains(query) ||
                                  unit.contains(query);
                            }).toList();

                      if (list.isEmpty) {
                        return const Center(child: Text('No products match your search.'));
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = list[i];
                          final price = p.price ?? p.pricePerQuantity;
                          return ListTile(
                            title: Text(p.name, overflow: TextOverflow.ellipsis),
                            subtitle: Text(price > 0 ? 'Price: ${price.toStringAsFixed(2)}' : 'No price'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop<Product>(context, p);
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}