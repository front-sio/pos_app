abstract class SupplierEvent {}

class FetchSuppliers extends SupplierEvent {
  final int page;
  final int limit;
  FetchSuppliers({this.page = 1, this.limit = 20});
}

class FetchSuppliersPage extends SupplierEvent {
  final int page;
  final int limit;
  FetchSuppliersPage(this.page, this.limit);
}

class SearchSuppliers extends SupplierEvent {
  final String query;
  SearchSuppliers(this.query);
}

class AddSupplier extends SupplierEvent {
  final Map<String, dynamic> data;
  AddSupplier(this.data);
}

class UpdateSupplierEvent extends SupplierEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateSupplierEvent(this.id, this.data);
}

class DeleteSupplierEvent extends SupplierEvent {
  final int id;
  DeleteSupplierEvent(this.id);
}