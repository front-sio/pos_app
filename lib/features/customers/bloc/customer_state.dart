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
  final bool hasMore;

  CustomersLoaded(
    this.customers, {
    this.searchQuery = '',
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [customers, searchQuery, hasMore];

  CustomersLoaded copyWith({
    List<Customer>? customers,
    String? searchQuery,
    bool? hasMore,
  }) {
    return CustomersLoaded(
      customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class CustomersError extends CustomerState {
  final String message;

  CustomersError(this.message);

  @override
  List<Object?> get props => [message];
}