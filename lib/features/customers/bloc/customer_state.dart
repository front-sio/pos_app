import 'package:equatable/equatable.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';

abstract class CustomerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CustomersLoading extends CustomerState {}

class CustomersLoaded extends CustomerState {
  final List<Customer> customers;
  final String searchQuery;

  CustomersLoaded(this.customers, {this.searchQuery = ''});

  @override
  List<Object?> get props => [customers, searchQuery];
}

class CustomersError extends CustomerState {
  final String message;
  CustomersError(this.message);

  @override
  List<Object?> get props => [message];
}