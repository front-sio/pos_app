import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/products/bloc/products_event.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';
import 'package:sales_app/utils/api_error_handler.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductService _productService;

  // De-duplicated in-memory source of truth
  final Map<int, Product> _byId = {};

  ProductsBloc({required ProductService productService})
      : _productService = productService,
        super(ProductsLoading()) {
    on<FetchProducts>(_onFetchProducts);
    on<FetchProductsPage>(_onFetchProductsPage);
    on<SearchProducts>(_onSearchProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  List<Product> get _allSorted {
    final list = _byId.values.toList();
    list.sort((a, b) => b.id.compareTo(a.id)); // newest first
    return list;
  }

  Future<void> _onFetchProducts(FetchProducts event, Emitter<ProductsState> emit) async {
    try {
      emit(ProductsLoading());
      final list = await _productService.getProducts();
      _byId
        ..clear()
        ..addEntries(list.map((p) => MapEntry(p.id, p)));
      emit(ProductsLoaded(_allSorted));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(ProductsError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onFetchProductsPage(FetchProductsPage event, Emitter<ProductsState> emit) async {
    try {
      final list = await _productService.getProducts(page: event.page, limit: event.limit);
      if (event.page == 1) _byId.clear(); // treat page 1 as refresh
      for (final p in list) {
        _byId[p.id] = p; // de-dup by id
      }
      emit(ProductsLoaded(_allSorted));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(ProductsError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  void _onSearchProducts(SearchProducts event, Emitter<ProductsState> emit) {
    final q = event.query.toLowerCase();
    final filtered = _allSorted.where((p) => p.name.toLowerCase().contains(q)).toList();
    emit(ProductsLoaded(filtered, searchQuery: event.query));
  }

  Future<void> _onAddProduct(AddProduct event, Emitter<ProductsState> emit) async {
    try {
      final created = await _productService.addProduct(event.productData);
      _byId[created.id] = created;
      emit(ProductsLoaded(_allSorted));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(ProductsError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onUpdateProduct(UpdateProductEvent event, Emitter<ProductsState> emit) async {
    try {
      await _productService.updateProduct(event.id, event.data);
      final updated = await _productService.getProductById(event.id);
      _byId[event.id] = updated;
      emit(ProductsLoaded(_allSorted));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(ProductsError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onDeleteProduct(DeleteProductEvent event, Emitter<ProductsState> emit) async {
    try {
      await _productService.deleteProduct(event.id);
      _byId.remove(event.id);
      emit(ProductsLoaded(_allSorted)); // reflect instantly in UI
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(ProductsError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }
}