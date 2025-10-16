import 'package:equatable/equatable.dart';
import 'package:sales_app/features/products/data/product_model.dart';

abstract class ProductsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final String searchQuery;
  ProductsLoaded(this.products, {this.searchQuery = ''});

  @override
  List<Object?> get props => [products, searchQuery];
}

class ProductsError extends ProductsState {
  final String message;
  ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}