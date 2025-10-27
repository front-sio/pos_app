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

class UpdateCustomerEvent extends CustomerEvent {
  final int id;
  final String name;
  UpdateCustomerEvent(this.id, this.name);
}

class DeleteCustomerEvent extends CustomerEvent {
  final int id;
  DeleteCustomerEvent(this.id);
}