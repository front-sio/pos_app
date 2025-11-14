import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';
import 'package:sales_app/features/customers/bloc/customer_state.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';
import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/utils/api_error_handler.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerService service;

  // Internal store with de-dup by ID
  final Map<int, Customer> _byId = {};
  final List<int> _order = [];
  final Set<int> _loadedPages = {};

  bool _hasMore = true;
  bool _isFetching = false;

  CustomerBloc({required this.service}) : super(CustomersLoading()) {
    on<FetchCustomers>(_onFetch);
    on<FetchCustomersPage>(_onFetchPage);
    on<SearchCustomers>(_onSearch);
    on<AddCustomer>(_onAdd);
    on<UpdateCustomerEvent>(_onUpdate);
    on<DeleteCustomerEvent>(_onDelete);
  }

  List<Customer> _list() => _order.map((id) => _byId[id]!).toList();

  void _upsertMany(List<Customer> items, {bool appendToEnd = true}) {
    for (final c in items) {
      if (_byId.containsKey(c.id)) {
        _byId[c.id] = c;
      } else {
        _byId[c.id] = c;
        if (appendToEnd) {
          _order.add(c.id);
        } else {
          _order.insert(0, c.id);
        }
      }
    }
  }

  void _upsertOne(Customer c, {bool toTop = false}) {
    final exists = _byId.containsKey(c.id);
    _byId[c.id] = c;
    if (exists) {
      // move position if toTop requested
      if (toTop) {
        _order.remove(c.id);
        _order.insert(0, c.id);
      }
    } else {
      if (toTop) {
        _order.insert(0, c.id);
      } else {
        _order.add(c.id);
      }
    }
  }

  void _removeById(int id) {
    if (_byId.remove(id) != null) {
      _order.remove(id);
    }
  }

  Future<void> _onFetch(FetchCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomersLoading());
    try {
      _byId.clear();
      _order.clear();
      _loadedPages.clear();
      _hasMore = true;
      await _fetchPageInternal(page: event.page, limit: event.limit);
      emit(CustomersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(CustomersError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onFetchPage(FetchCustomersPage event, Emitter<CustomerState> emit) async {
    try {
      if (_isFetching) return;
      if (_loadedPages.contains(event.page)) return;
      if (!_hasMore && event.page > 1) return;

      await _fetchPageInternal(page: event.page, limit: event.limit);

      // Preserve possible searchQuery from current state
      final current = state is CustomersLoaded ? state as CustomersLoaded : null;
      emit(CustomersLoaded(
        _list(),
        hasMore: _hasMore,
        searchQuery: current?.searchQuery ?? '',
      ));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(CustomersError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _fetchPageInternal({required int page, required int limit}) async {
    _isFetching = true;
    try {
      final list = await service.getCustomers(page: page, limit: limit);
      _loadedPages.add(page);
      _upsertMany(list, appendToEnd: true);
      _hasMore = list.length >= limit;
    } finally {
      _isFetching = false;
    }
  }

  void _onSearch(SearchCustomers event, Emitter<CustomerState> emit) {
    final q = event.query.trim().toLowerCase();
    final all = _list();
    final filtered = q.isEmpty
        ? all
        : all.where((c) => c.name.toLowerCase().contains(q)).toList();
    emit(CustomersLoaded(filtered, searchQuery: event.query, hasMore: _hasMore));
  }

  Future<void> _onAdd(AddCustomer event, Emitter<CustomerState> emit) async {
    try {
      final created = await service.createCustomer(event.name);
      // Upsert and move to top, removing any older duplicate
      _upsertOne(created, toTop: true);
      emit(CustomersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(CustomersError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onUpdate(UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await service.updateCustomer(event.id, event.name);
      final updated = await service.getCustomerById(event.id);
      _upsertOne(updated, toTop: false);
      emit(CustomersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(CustomersError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onDelete(DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await service.deleteCustomer(event.id);
      _removeById(event.id);
      emit(CustomersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(CustomersError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }
}