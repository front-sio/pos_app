import 'sale_item.dart';

class NewSaleDto {
  final int? customerId;
  final List<SaleItem> items;
  final double? paidAmount;
  final double? orderDiscountAmount;

  const NewSaleDto({
    this.customerId,
    required this.items,
    this.paidAmount,
    this.orderDiscountAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'paid_amount': paidAmount,
      'order_discount_amount': orderDiscountAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}