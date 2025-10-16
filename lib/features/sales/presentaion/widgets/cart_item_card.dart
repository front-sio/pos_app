import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/sales/models/line_edit.dart';

class CartItemCard extends StatelessWidget {
  final MapEntry<Product, int> entry;
  final LineEdit lineEdit;
  final void Function(Product, int) onQuantityChanged;
  final void Function(Product) onRemove;

  const CartItemCard({
    super.key,
    required this.entry,
    required this.lineEdit,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = entry.key;
    final qty = entry.value;
    
    final listPrice = product.price ?? 0.0;
    final unitPrice = lineEdit.unitPriceCtrl.text.isEmpty
        ? listPrice
        : double.tryParse(lineEdit.unitPriceCtrl.text) ?? listPrice;
    final lineTotal = unitPrice * qty;
    final priceChanged = (unitPrice - listPrice).abs() > 0.0001;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                  child: Text(product.name.isNotEmpty ? product.name[0] : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.kError,
                  onPressed: () => onRemove(product),
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding),
            
            // Controls
            Row(
              children: [
                // Quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantity'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => onQuantityChanged(product, qty - 1),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: lineEdit.qtyCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                final n = int.tryParse(v) ?? 0;
                                onQuantityChanged(product, n);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => onQuantityChanged(product, qty + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: AppSizes.padding),
                
                // Unit Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit Price (list \$${listPrice.toStringAsFixed(2)})'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: lineEdit.unitPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.padding),
            
            // Totals & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Total: \$${lineTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (priceChanged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (unitPrice > listPrice 
                        ? Colors.amber 
                        : AppColors.kError).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      unitPrice > listPrice ? 'Over List' : 'Under List',
                      style: TextStyle(
                        color: unitPrice > listPrice 
                          ? Colors.amber.shade900
                          : AppColors.kError,
                        fontWeight: FontWeight.w500,
                      ),
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