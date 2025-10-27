import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_event.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_state.dart';
import 'package:sales_app/features/suppliers/data/supplier_model.dart';
import 'package:sales_app/features/suppliers/services/supplier_service.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierService service;

  // Internal store with de-dup by ID
  final Map<int, Supplier> _byId = {};
  final List<int> _order = [];
  final Set<int> _loadedPages = {};

  bool _hasMore = true;
  bool _isFetching = false;

  SupplierBloc({required this.service}) : super(SuppliersLoading()) {
    on<FetchSuppliers>(_onFetch);
    on<FetchSuppliersPage>(_onFetchPage);
    on<SearchSuppliers>(_onSearch);
    on<AddSupplier>(_onAdd);
    on<UpdateSupplierEvent>(_onUpdate);
    on<DeleteSupplierEvent>(_onDelete);
  }

  List<Supplier> _list() => _order.map((id) => _byId[id]!).toList();

  void _upsertMany(List<Supplier> items, {bool appendToEnd = true}) {
    for (final s in items) {
      if (_byId.containsKey(s.id)) {
        _byId[s.id] = s;
      } else {
        _byId[s.id] = s;
        if (appendToEnd) {
          _order.add(s.id);
        } else {
          _order.insert(0, s.id);
        }
      }
    }
  }

  void _upsertOne(Supplier s, {bool toTop = false}) {
    final exists = _byId.containsKey(s.id);
    _byId[s.id] = s;
    if (exists) {
      if (toTop) {
        _order.remove(s.id);
        _order.insert(0, s.id);
      }
    } else {
      if (toTop) {
        _order.insert(0, s.id);
      } else {
        _order.add(s.id);
      }
    }
  }

  void _removeById(int id) {
    if (_byId.remove(id) != null) {
      _order.remove(id);
    }
  }

  Future<void> _onFetch(FetchSuppliers event, Emitter<SupplierState> emit) async {
    emit(SuppliersLoading());
    try {
      _byId.clear();
      _order.clear();
      _loadedPages.clear();
      _hasMore = true;
      await _fetchPageInternal(page: event.page, limit: event.limit);
      emit(SuppliersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> _onFetchPage(FetchSuppliersPage event, Emitter<SupplierState> emit) async {
    try {
      if (_isFetching) return;
      if (_loadedPages.contains(event.page)) return;
      if (!_hasMore && event.page > 1) return;

      await _fetchPageInternal(page: event.page, limit: event.limit);

      final current = state is SuppliersLoaded ? state as SuppliersLoaded : null;
      emit(SuppliersLoaded(
        _list(),
        hasMore: _hasMore,
        searchQuery: current?.searchQuery ?? '',
      ));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> _fetchPageInternal({required int page, required int limit}) async {
    _isFetching = true;
    try {
      final list = await service.getSuppliers(page: page, limit: limit);
      _loadedPages.add(page);
      _upsertMany(list, appendToEnd: true);
      _hasMore = list.length >= limit;
    } finally {
      _isFetching = false;
    }
  }

  void _onSearch(SearchSuppliers event, Emitter<SupplierState> emit) {
    final q = event.query.trim().toLowerCase();
    final all = _list();
    final filtered = q.isEmpty
        ? all
        : all.where((s) {
            return s.name.toLowerCase().contains(q) ||
                (s.email ?? '').toLowerCase().contains(q) ||
                (s.phone ?? '').toLowerCase().contains(q);
          }).toList();
    emit(SuppliersLoaded(filtered, searchQuery: event.query, hasMore: _hasMore));
  }

  Future<void> _onAdd(AddSupplier event, Emitter<SupplierState> emit) async {
    try {
      final created = await service.createSupplier(event.data);
      _upsertOne(created, toTop: true);
      emit(SuppliersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateSupplierEvent event, Emitter<SupplierState> emit) async {
    try {
      await service.updateSupplier(event.id, event.data);
      final updated = await service.getSupplierById(event.id);
      _upsertOne(updated, toTop: false);
      emit(SuppliersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteSupplierEvent event, Emitter<SupplierState> emit) async {
    try {
      await service.deleteSupplier(event.id);
      _removeById(event.id);
      emit(SuppliersLoaded(_list(), hasMore: _hasMore));
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }
}