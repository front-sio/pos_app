import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_event.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_state.dart';
import 'package:sales_app/features/suppliers/data/supplier_model.dart';
import 'package:sales_app/features/suppliers/services/supplier_service.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierService service;
  final List<Supplier> _all = [];

  SupplierBloc({required this.service}) : super(SuppliersLoading()) {
    on<FetchSuppliers>(_onFetch);
    on<FetchSuppliersPage>(_onFetchPage);
    on<SearchSuppliers>(_onSearch);
    on<AddSupplier>(_onAdd);
    on<UpdateSupplierEvent>(_onUpdate);
    on<DeleteSupplierEvent>(_onDelete);
  }

  Future<void> _onFetch(FetchSuppliers event, Emitter<SupplierState> emit) async {
    emit(SuppliersLoading());
    try {
      _all
        ..clear()
        ..addAll(await service.getSuppliers(page: 1, limit: 20));
      emit(SuppliersLoaded(List.of(_all)));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> _onFetchPage(FetchSuppliersPage event, Emitter<SupplierState> emit) async {
    try {
      final list = await service.getSuppliers(page: event.page, limit: event.limit);
      _all.addAll(list);
      emit(SuppliersLoaded(List.of(_all)));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  void _onSearch(SearchSuppliers event, Emitter<SupplierState> emit) {
    final q = event.query.toLowerCase();
    final filtered = _all.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.email ?? '').toLowerCase().contains(q) ||
          (s.phone ?? '').toLowerCase().contains(q);
    }).toList();
    emit(SuppliersLoaded(filtered, searchQuery: event.query));
  }

  Future<void> _onAdd(AddSupplier event, Emitter<SupplierState> emit) async {
    try {
      final created = await service.createSupplier(event.data);
      _all.insert(0, created);
      emit(SuppliersLoaded(List.of(_all)));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateSupplierEvent event, Emitter<SupplierState> emit) async {
    try {
      await service.updateSupplier(event.id, event.data);
      final updated = await service.getSupplierById(event.id);
      final idx = _all.indexWhere((s) => s.id == event.id);
      if (idx >= 0) _all[idx] = updated;
      emit(SuppliersLoaded(List.of(_all)));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteSupplierEvent event, Emitter<SupplierState> emit) async {
    try {
      await service.deleteSupplier(event.id);
      _all.removeWhere((s) => s.id == event.id);
      emit(SuppliersLoaded(List.of(_all)));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }
}