import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/stocks/bloc/stock_event.dart';
import 'package:sales_app/features/stocks/bloc/stock_state.dart';
import 'package:sales_app/features/products/services/product_service.dart' as products;
import 'package:sales_app/features/stocks/data/stock_transaction_model.dart';
import 'package:sales_app/features/stocks/services/stock_service.dart' as stocks;

class StockBloc extends Bloc<StockEvent, StockState> {
  final products.ProductService productService;
  final stocks.StockService stockService;
  final int _itemsPerPage = 20;

  // Products for Add Stock flow and enrichment
  final List<Product> _allProducts = [];
  final Map<int, Product> _productCache = {}; // for quick productId -> Product
  int _currentProductsPage = 1;
  String? _currentProductsQuery;
  StockFilter _currentFilter = StockFilter.all;

  // Transactions (source for view/edit/delete)
  List<StockTransaction> _allTransactions = [];
  String? _currentTransactionsQuery;

  // Prevent overlapping fetches
  bool _isFetchingProducts = false;
  bool _isFetchingTransactions = false;

  StockBloc({
    required this.productService,
    required this.stockService,
  }) : super(StockInitial()) {
    // Products events
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
    on<FilterProducts>(_onFilterProducts);
    on<AddStockToProduct>(_onAddStockToProduct);

    // Transactions events
    on<LoadTransactions>(_onLoadTransactions);
    on<SearchTransactions>(_onSearchTransactions);
    on<UpdateStockTransactionEvent>(_onUpdateTransaction);
    on<DeleteStockTransactionEvent>(_onDeleteTransaction);
  }

  // -------------------- Products (Add Stock) --------------------
  Future<void> _onLoadProducts(LoadProducts event, Emitter<StockState> emit) async {
    if (_isFetchingProducts) return;
    _isFetchingProducts = true;

    final isInitial = event.page == 1 || state is StockInitial;
    final hasQueryChanged = event.query != _currentProductsQuery;
    final hasFilterChanged = event.filter != _currentFilter;

    if (isInitial || hasQueryChanged || hasFilterChanged) {
      _currentProductsPage = 1;
      _currentProductsQuery = event.query;
      _currentFilter = event.filter;
      _allProducts.clear();
      emit(StockLoading(products: _allProducts, transactions: _allTransactions));
    } else {
      if (state is! StockLoaded) {
        _isFetchingProducts = false;
        return;
      }
      final loaded = state as StockLoaded;
      if (loaded.isLoadingMore || loaded.hasReachedMax) {
        _isFetchingProducts = false;
        return;
      }
      emit(loaded.copyWith(isLoadingMore: true));
      _currentProductsPage++;
    }

    try {
      final newProducts = await productService.getProducts(
        page: _currentProductsPage,
        limit: _itemsPerPage,
      );

      // Update cache
      for (final p in newProducts) {
        _productCache[p.id] = p;
      }

      if (_currentProductsPage == 1) {
        _allProducts
          ..clear()
          ..addAll(newProducts);
      } else {
        final existingIds = _allProducts.map((p) => p.id).toSet();
        _allProducts.addAll(newProducts.where((p) => !existingIds.contains(p.id)));
      }

      final hasReachedMax = newProducts.isEmpty || newProducts.length < _itemsPerPage;
      final filteredProducts = _applyProductFilters(_allProducts, _currentFilter, _currentProductsQuery);

      _emitCombined(
        emit,
        products: _allProducts,
        filteredProducts: filteredProducts,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
      );
    } catch (e) {
      emit(StockError(e.toString()));
    } finally {
      _isFetchingProducts = false;
    }
  }

  void _onSearchProducts(SearchProducts event, Emitter<StockState> emit) {
    _currentProductsQuery = event.query;
    if (state is StockLoaded) {
      final s = state as StockLoaded;
      final filteredProducts = _applyProductFilters(s.products, _currentFilter, _currentProductsQuery);
      emit(s.copyWith(filteredProducts: filteredProducts, currentQuery: _currentProductsQuery));
    }
  }

  void _onFilterProducts(FilterProducts event, Emitter<StockState> emit) {
    _currentFilter = event.filter;
    if (state is StockLoaded) {
      final s = state as StockLoaded;
      final filteredProducts = _applyProductFilters(s.products, _currentFilter, _currentProductsQuery);
      emit(s.copyWith(filteredProducts: filteredProducts, currentFilter: _currentFilter));
    } else if (state is StockInitial) {
      add(LoadProducts(page: 1, query: _currentProductsQuery, filter: _currentFilter));
    }
  }

  Future<void> _onAddStockToProduct(AddStockToProduct event, Emitter<StockState> emit) async {
    // 1) Optimistic: insert a temporary transaction so user sees it immediately
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch; // negative id to avoid collisions
    final productName = event.productName ?? _productCache[event.productId]?.name;

    final tempTxn = StockTransaction(
      id: tempId,
      productId: event.productId,
      userId: event.userId,
      amountAdded: event.amountAdded,
      pricePerUnit: event.pricePerUnit,
      totalCost: event.amountAdded * event.pricePerUnit,
      date: now,
      productName: productName,
      unitName: null,
      supplierId: event.supplierId,
    );

    _allTransactions = [tempTxn, ..._allTransactions];
    final filteredAfterTemp = _applyTxnSearch(_allTransactions, _currentTransactionsQuery);
    _emitCombined(
      emit,
      transactions: _allTransactions,
      filteredTransactions: filteredAfterTemp,
    );

    // 2) Persist to backend, then silently refresh to reconcile with actual record
    try {
      await productService.addStock(
        productId: event.productId,
        amount: event.amountAdded,
        pricePerUnit: event.pricePerUnit,
        userId: event.userId,
        supplierId: event.supplierId,
      );

      // Silent refresh (no loading spinner) to replace temp with real one
      add(LoadTransactions(page: 1, query: _currentTransactionsQuery, silent: true));

      // Optionally refresh products (for quantities)
      add(LoadProducts(page: 1, query: _currentProductsQuery, filter: _currentFilter));
    } catch (e) {
      // Rollback optimistic insert on failure
      _allTransactions.removeWhere((t) => t.id == tempId);
      final filtered = _applyTxnSearch(_allTransactions, _currentTransactionsQuery);
      _emitCombined(emit, transactions: _allTransactions, filteredTransactions: filtered);
      emit(StockError(e.toString()));
    }
  }

  List<Product> _applyProductFilters(List<Product> products, StockFilter filter, String? query) {
    Iterable<Product> result = products;

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      result = result.where((p) => p.name.toLowerCase().contains(q));
    }

    switch (filter) {
      case StockFilter.outOfStock:
        result = result.where((p) => p.quantity == 0.0);
        break;
      case StockFilter.all:
        break;
    }
    return result.toList(growable: false);
  }

  // -------------------- Transactions (View/Edit/Delete) --------------------
  Future<void> _onLoadTransactions(LoadTransactions event, Emitter<StockState> emit) async {
    if (_isFetchingTransactions) return;
    _isFetchingTransactions = true;

    if (!event.silent) {
      // Only show loading when not silent
      emit(StockLoading(products: _allProducts, transactions: _allTransactions));
    }

    try {
      final txns = await stockService.getTransactions();
      // Enrich with product names using cache and API lookups
      final enriched = await _enrichTransactionsWithProductNames(txns);
      _allTransactions = enriched;

      final filtered = _applyTxnSearch(_allTransactions, event.query ?? _currentTransactionsQuery);

      _emitCombined(
        emit,
        transactions: _allTransactions,
        filteredTransactions: filtered,
        hasReachedMax: true, // until backend supports pagination
        isLoadingMore: false,
        currentQuery: event.query ?? _currentTransactionsQuery,
      );
      _currentTransactionsQuery = event.query ?? _currentTransactionsQuery;
    } catch (e) {
      emit(StockError(e.toString()));
    } finally {
      _isFetchingTransactions = false;
    }
  }

  void _onSearchTransactions(SearchTransactions event, Emitter<StockState> emit) {
    _currentTransactionsQuery = event.query;
    if (state is StockLoaded) {
      final s = state as StockLoaded;
      final filtered = _applyTxnSearch(s.transactions, event.query);
      emit(s.copyWith(filteredTransactions: filtered, currentQuery: event.query));
    }
  }

  Future<void> _onUpdateTransaction(UpdateStockTransactionEvent event, Emitter<StockState> emit) async {
    try {
      await stockService.updateTransaction(event.id, event.updated);
      // Reload to reflect changes (silent to avoid flicker)
      add(LoadTransactions(page: 1, query: _currentTransactionsQuery, silent: true));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(DeleteStockTransactionEvent event, Emitter<StockState> emit) async {
    try {
      await stockService.deleteTransaction(event.id);
      // Optimistic remove
      _allTransactions.removeWhere((t) => t.id == event.id);
      final filtered = _applyTxnSearch(_allTransactions, _currentTransactionsQuery);
      _emitCombined(
        emit,
        transactions: _allTransactions,
        filteredTransactions: filtered,
      );
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  List<StockTransaction> _applyTxnSearch(List<StockTransaction> txns, String? query) {
    if (query == null || query.trim().isEmpty) return List.unmodifiable(txns);
    final q = query.toLowerCase().trim();
    return txns.where((t) {
      final matchesName = (t.productName ?? '').toLowerCase().contains(q);
      final matchesNumbers = t.amountAdded.toString().contains(q) ||
          t.pricePerUnit.toString().contains(q) ||
          t.totalCost.toString().contains(q) ||
          t.productId.toString() == q ||
          t.id.toString() == q;
      return matchesName || matchesNumbers;
    }).toList(growable: false);
  }

  Future<List<StockTransaction>> _enrichTransactionsWithProductNames(List<StockTransaction> txns) async {
    // Build set of needed product IDs
    final needed = <int>{};
    for (final t in txns) {
      if ((_productCache[t.productId] == null) || (t.productName == null || t.productName!.isEmpty)) {
        needed.add(t.productId);
      }
    }

    // Fetch missing products
    if (needed.isNotEmpty) {
      final futures = needed.map((id) async {
        try {
          final p = await productService.getProductById(id);
          _productCache[id] = p;
        } catch (_) {
          // Ignore individual failures; fallback remains "Product #id"
        }
      }).toList();
      await Future.wait(futures);
    }

    // Return enriched copies
    return txns.map((t) {
      final p = _productCache[t.productId];
      if (p == null) return t;
      return t.copyWith(
        productName: p.name,
        // Optionally map a unit name if your Product has it (e.g., p.unitName)
        // unitName: p.unitName,
      );
    }).toList(growable: false);
  }

  // Emit a combined state snapshot so UI can read either products (add stock) or transactions (view/edit/delete)
  void _emitCombined(
    Emitter<StockState> emit, {
    List<Product>? products,
    List<Product>? filteredProducts,
    List<StockTransaction>? transactions,
    List<StockTransaction>? filteredTransactions,
    bool? hasReachedMax,
    bool? isLoadingMore,
    StockFilter? currentFilter,
    String? currentQuery,
  }) {
    final prev = state;
    if (prev is StockLoaded) {
      emit(prev.copyWith(
        products: products ?? prev.products,
        filteredProducts: filteredProducts ?? prev.filteredProducts,
        transactions: transactions ?? prev.transactions,
        filteredTransactions: filteredTransactions ?? prev.filteredTransactions,
        hasReachedMax: hasReachedMax ?? prev.hasReachedMax,
        isLoadingMore: isLoadingMore ?? prev.isLoadingMore,
        currentFilter: currentFilter ?? prev.currentFilter,
        currentQuery: currentQuery ?? prev.currentQuery,
      ));
    } else {
      emit(StockLoaded(
        products: products ?? const [],
        filteredProducts: filteredProducts ?? const [],
        transactions: transactions ?? const [],
        filteredTransactions: filteredTransactions ?? const [],
        hasReachedMax: hasReachedMax ?? false,
        isLoadingMore: isLoadingMore ?? false,
        currentFilter: currentFilter ?? StockFilter.all,
        currentQuery: currentQuery,
      ));
    }
  }
}