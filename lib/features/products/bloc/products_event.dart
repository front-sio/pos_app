abstract class ProductsEvent {}

class FetchProducts extends ProductsEvent {}

class FetchProductsPage extends ProductsEvent {
  final int page;
  final int limit;
  FetchProductsPage(this.page, this.limit);
}

class SearchProducts extends ProductsEvent {
  final String query;
  SearchProducts(this.query);
}

class AddProduct extends ProductsEvent {
  final Map<String, dynamic> productData;
  AddProduct(this.productData);
}

class UpdateProductEvent extends ProductsEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateProductEvent(this.id, this.data);
}

class DeleteProductEvent extends ProductsEvent {
  final int id;
  DeleteProductEvent(this.id);
}