import 'package:equatable/equatable.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object?> get props => [];
}

// Filters for products list (used only for Add Stock flow display if needed)
enum StockFilter { all, outOfStock }

// Existing: Products pagination/search (kept for Add Stock flow)
class LoadProducts extends StockEvent {
  final int page; // use -1 to load next page
  final String? query;
  final StockFilter filter;
  const LoadProducts({required this.page, this.query, this.filter = StockFilter.all});
  @override
  List<Object?> get props => [page, query, filter];
}

class SearchProducts extends StockEvent {
  final String query;
  const SearchProducts(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterProducts extends StockEvent {
  final StockFilter filter;
  const FilterProducts(this.filter);
  @override
  List<Object?> get props => [filter];
}

// Add stock (depends on product)
class AddStockToProduct extends StockEvent {
  final int productId;
  final double amountAdded;
  final double pricePerUnit;
  final int userId;

  // Optional: for instant UI + backend linkage
  final String? productName;
  final int? supplierId;

  const AddStockToProduct({
    required this.productId,
    required this.amountAdded,
    required this.pricePerUnit,
    required this.userId,
    this.productName,
    this.supplierId,
  });

  @override
  List<Object?> get props => [productId, amountAdded, pricePerUnit, userId, productName, supplierId];
}

// Transactions listing/search
class LoadTransactions extends StockEvent {
  final int page; // reserved for future pagination; currently unused
  final String? query; // search by product name or numeric fields
  final bool silent; // Silently refresh without showing loading spinner

  const LoadTransactions({
    required this.page,
    this.query,
    this.silent = false,
  });

  @override
  List<Object?> get props => [page, query, silent];
}

class SearchTransactions extends StockEvent {
  final String query;
  const SearchTransactions(this.query);
  @override
  List<Object?> get props => [query];
}

// Transaction CRUD
class UpdateStockTransactionEvent extends StockEvent {
  final int id;
  final Map<String, dynamic> updated;
  const UpdateStockTransactionEvent(this.id, this.updated);
  @override
  List<Object?> get props => [id, updated];
}

class DeleteStockTransactionEvent extends StockEvent {
  final int id;
  const DeleteStockTransactionEvent(this.id);
  @override
  List<Object?> get props => [id];
}