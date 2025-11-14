import 'package:equatable/equatable.dart';
import 'package:sales_app/features/suppliers/data/supplier_model.dart';

abstract class SupplierState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SuppliersLoading extends SupplierState {}

class SuppliersLoaded extends SupplierState {
  final List<Supplier> suppliers;
  final String searchQuery;
  final bool hasMore;

  SuppliersLoaded(
    this.suppliers, {
    this.searchQuery = '',
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [suppliers, searchQuery, hasMore];

  SuppliersLoaded copyWith({
    List<Supplier>? suppliers,
    String? searchQuery,
    bool? hasMore,
  }) {
    return SuppliersLoaded(
      suppliers ?? this.suppliers,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SuppliersError extends SupplierState {
  final String message;
  final bool isNetworkError;

  SuppliersError(this.message, {this.isNetworkError = false});

  @override
  List<Object?> get props => [message, isNetworkError];
}