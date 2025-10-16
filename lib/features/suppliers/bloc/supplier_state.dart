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

  SuppliersLoaded(this.suppliers, {this.searchQuery = ''});

  @override
  List<Object?> get props => [suppliers, searchQuery];
}

class SuppliersError extends SupplierState {
  final String message;
  SuppliersError(this.message);

  @override
  List<Object?> get props => [message];
}