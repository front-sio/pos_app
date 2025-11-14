import 'package:equatable/equatable.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/stocks/data/stock_transaction_model.dart';
import 'package:sales_app/features/stocks/bloc/stock_event.dart';

abstract class StockState extends Equatable {
  const StockState();
  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

// Loading state can optionally carry last known lists
class StockLoading extends StockState {
  final List<Product> products;
  final List<StockTransaction> transactions;
  const StockLoading({this.products = const [], this.transactions = const []});
  @override
  List<Object?> get props => [products, transactions];
}

class StockLoaded extends StockState {
  // Products (kept for Add Stock flow)
  final List<Product> products;
  final List<Product> filteredProducts;

  // Transactions (source of truth for view/edit/delete)
  final List<StockTransaction> transactions;
  final List<StockTransaction> filteredTransactions;

  // Paging/loading flags (applicable to either collection as needed)
  final bool hasReachedMax;
  final bool isLoadingMore;

  // Current product filter/search (legacy)
  final StockFilter currentFilter;
  final String? currentQuery;

  const StockLoaded({
    required this.products,
    required this.filteredProducts,
    required this.transactions,
    required this.filteredTransactions,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.currentFilter = StockFilter.all,
    this.currentQuery,
  });

  StockLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    List<StockTransaction>? transactions,
    List<StockTransaction>? filteredTransactions,
    bool? hasReachedMax,
    bool? isLoadingMore,
    StockFilter? currentFilter,
    String? currentQuery,
  }) {
    return StockLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentFilter: currentFilter ?? this.currentFilter,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }

  @override
  List<Object?> get props => [
        products,
        filteredProducts,
        transactions,
        filteredTransactions,
        hasReachedMax,
        isLoadingMore,
        currentFilter,
        currentQuery,
      ];
}

class StockError extends StockState {
  final String message;
  final bool isNetworkError;
  
  const StockError(this.message, {this.isNetworkError = false});
  
  @override
  List<Object?> get props => [message, isNetworkError];
}