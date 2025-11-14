import 'package:equatable/equatable.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/sales/models/line_edit.dart'; // LineOverride type

abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object> get props => [];
}

class LoadSales extends SalesEvent {
  const LoadSales();
}

class AddSale extends SalesEvent {
  final int customerId;
  final double paidAmount;
  final double orderDiscountAmount;
  final List<LineOverride> overrides;

  const AddSale({
    required this.customerId,
    this.paidAmount = 0.0,
    this.orderDiscountAmount = 0.0,
    this.overrides = const [],
  });

  @override
  List<Object> get props => [customerId, paidAmount, orderDiscountAmount, overrides];
}

class AddItemToCart extends SalesEvent {
  final Product product;

  const AddItemToCart(this.product);

  @override
  List<Object> get props => [product];
}

class RemoveItemFromCart extends SalesEvent {
  final Product product;

  const RemoveItemFromCart(this.product);

  @override
  List<Object> get props => [product];
}

class UpdateItemQuantity extends SalesEvent {
  final Product product;
  final int quantity;

  const UpdateItemQuantity(this.product, this.quantity);

  @override
  List<Object> get props => [product, quantity];
}

class ResetCart extends SalesEvent {
  const ResetCart();
}

class AddItemFromBarcode extends SalesEvent {
  final String barcode;

  const AddItemFromBarcode(this.barcode);

  @override
  List<Object> get props => [barcode];
}