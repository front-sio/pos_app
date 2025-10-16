import 'package:flutter/material.dart';

/// Per-line editor state for a product row (quantity and unit price).
class LineEdit {
  final TextEditingController unitPriceCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  void dispose() {
    unitPriceCtrl.dispose();
    qtyCtrl.dispose();
  }
}

/// Line-level override passed to the backend alongside the cart.
/// Only overrides the unit price (amount per unit).
class LineOverride {
  final int productId;
  final double? unitPrice;

  const LineOverride({
    required this.productId,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'product_id': productId,
        if (unitPrice != null) 'unit_price': unitPrice,
      };
}