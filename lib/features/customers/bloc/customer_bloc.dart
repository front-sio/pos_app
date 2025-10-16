import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';
import 'package:sales_app/features/customers/bloc/customer_state.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';
import 'package:sales_app/features/customers/services/customer_services.dart';


class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerService service;
  final List<Customer> _all = [];

  CustomerBloc({required this.service}) : super(CustomersLoading()) {
    on<FetchCustomers>(_onFetch);
    on<FetchCustomersPage>(_onFetchPage);
    on<SearchCustomers>(_onSearch);
    on<AddCustomer>(_onAdd);
    on<UpdateCustomerEvent>(_onUpdate);
    on<DeleteCustomerEvent>(_onDelete);
  }

  Future<void> _onFetch(FetchCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomersLoading());
    try {
      _all
        ..clear()
        ..addAll(await service.getCustomers(page: 1, limit: 20));
      emit(CustomersLoaded(List.of(_all)));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onFetchPage(FetchCustomersPage event, Emitter<CustomerState> emit) async {
    try {
      final list = await service.getCustomers(page: event.page, limit: event.limit);
      _all.addAll(list);
      emit(CustomersLoaded(List.of(_all)));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  void _onSearch(SearchCustomers event, Emitter<CustomerState> emit) {
    final q = event.query.toLowerCase();
    final filtered = _all.where((c) => c.name.toLowerCase().contains(q)).toList();
    emit(CustomersLoaded(filtered, searchQuery: event.query));
  }

  Future<void> _onAdd(AddCustomer event, Emitter<CustomerState> emit) async {
    try {
      final created = await service.createCustomer(event.name);
      _all.insert(0, created);
      emit(CustomersLoaded(List.of(_all)));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await service.updateCustomer(event.id, event.name);
      final updated = await service.getCustomerById(event.id);
      final idx = _all.indexWhere((c) => c.id == event.id);
      if (idx >= 0) _all[idx] = updated;
      emit(CustomersLoaded(List.of(_all)));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await service.deleteCustomer(event.id);
      _all.removeWhere((c) => c.id == event.id);
      emit(CustomersLoaded(List.of(_all)));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }
}