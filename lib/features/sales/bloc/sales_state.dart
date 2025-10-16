import 'package:equatable/equatable.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/sales/data/sales_model.dart';


abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object> get props => [];
}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class SalesLoaded extends SalesState {
  final List<Sale> sales;

  const SalesLoaded(this.sales);

  @override
  List<Object> get props => [sales];
}

class CartUpdated extends SalesState {
  final Map<Product, int> cart;

  const CartUpdated(this.cart);

  @override
  List<Object> get props => [cart];
}

class SalesError extends SalesState {
  final String message;

  const SalesError(this.message);

  @override
  List<Object> get props => [message];
}

class SalesOperationSuccess extends SalesState {
  final String message;

  const SalesOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}