import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/sales/models/line_edit.dart';

class CartItemCard extends StatefulWidget {
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
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  late int _lastValidQty;

  @override
  void initState() {
    super.initState();
    _lastValidQty = widget.entry.value > 0 ? widget.entry.value : 1;
    if (widget.lineEdit.qtyCtrl.text.isEmpty) {
      widget.lineEdit.qtyCtrl.text = _lastValidQty.toString();
    }
  }

  void _applyQty(int q) {
    if (q <= 0) return; // Avoid accidental removal while editing
    _lastValidQty = q;
    widget.onQuantityChanged(widget.entry.key, q);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.entry.key;
    final qty = widget.entry.value;

    final listPrice = product.price ?? product.pricePerQuantity;
    final unitPrice = widget.lineEdit.unitPriceCtrl.text.isEmpty
        ? listPrice
        : double.tryParse(widget.lineEdit.unitPriceCtrl.text) ?? listPrice;
    final lineTotal = unitPrice * qty;
    final priceChanged = (unitPrice - listPrice).abs() > 0.0001;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.kPrimary.withValues(alpha: 0.1),
                  child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.kError,
                  onPressed: () => widget.onRemove(product),
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding),

            // Controls
            Row(
              children: [
                // Quantity control
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
                            onPressed: () {
                              final next = (_lastValidQty - 1);
                              if (next > 0) {
                                widget.lineEdit.qtyCtrl.text = next.toString();
                                _applyQty(next);
                              }
                            },
                          ),
                          SizedBox(
                            width: 70,
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) {
                                  final txt = widget.lineEdit.qtyCtrl.text.trim();
                                  final parsed = int.tryParse(txt);
                                  if (parsed == null || parsed <= 0) {
                                    widget.lineEdit.qtyCtrl.text = _lastValidQty.toString();
                                  } else if (parsed != _lastValidQty) {
                                    _applyQty(parsed);
                                  }
                                }
                              },
                              child: TextField(
                                controller: widget.lineEdit.qtyCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) {
                                  if (v.isEmpty) return; // editing in progress
                                  final n = int.tryParse(v);
                                  if (n == null || n <= 0) return;
                                  _applyQty(n);
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              final next = _lastValidQty + 1;
                              widget.lineEdit.qtyCtrl.text = next.toString();
                              _applyQty(next);
                            },
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
                      Text('Unit Price (list ${listPrice.toStringAsFixed(2)})'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: widget.lineEdit.unitPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
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
                  'Line Total: ${lineTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (priceChanged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (unitPrice > listPrice ? Colors.amber : AppColors.kError).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      unitPrice > listPrice ? 'Over List' : 'Under List',
                      style: TextStyle(
                        color: unitPrice > listPrice ? Colors.amber.shade900 : AppColors.kError,
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