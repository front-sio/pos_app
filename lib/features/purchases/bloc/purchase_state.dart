import 'package:equatable/equatable.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';

abstract class PurchaseState extends Equatable {
  const PurchaseState();
  @override
  List<Object?> get props => [];
}

class PurchaseInitial extends PurchaseState {}

class PurchaseLoading extends PurchaseState {}

class PurchaseLoaded extends PurchaseState {
  final List<Purchase> purchases;
  const PurchaseLoaded(this.purchases);
  @override
  List<Object?> get props => [purchases];
}

class PurchaseError extends PurchaseState {
  final String message;
  final bool isNetworkError;
  
  const PurchaseError(this.message, {this.isNetworkError = false});
  
  @override
  List<Object?> get props => [message, isNetworkError];
}

class PurchaseOperationSuccess extends PurchaseState {
  final String message;
  const PurchaseOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}