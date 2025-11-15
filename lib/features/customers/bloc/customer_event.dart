import 'package:sales_app/features/customers/data/customer_model.dart';

abstract class CustomerEvent {}

class FetchCustomers extends CustomerEvent {
  final int page;
  final int limit;
  FetchCustomers({this.page = 1, this.limit = 20});
}

class FetchCustomersPage extends CustomerEvent {
  final int page;
  final int limit;
  FetchCustomersPage(this.page, this.limit);
}

class SearchCustomers extends CustomerEvent {
  final String query;
  SearchCustomers(this.query);
}

class AddCustomer extends CustomerEvent {
  final String name;
  AddCustomer(this.name);
}

class AddCustomerWithDetails extends CustomerEvent {
  final Customer customer;
  AddCustomerWithDetails(this.customer);
}

class UpdateCustomerEvent extends CustomerEvent {
  final int id;
  final String name;
  UpdateCustomerEvent(this.id, this.name);
}

class UpdateCustomerWithDetails extends CustomerEvent {
  final Customer customer;
  UpdateCustomerWithDetails(this.customer);
}

class DeleteCustomerEvent extends CustomerEvent {
  final int id;
  DeleteCustomerEvent(this.id);
}