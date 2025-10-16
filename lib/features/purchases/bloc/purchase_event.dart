import 'package:equatable/equatable.dart';

abstract class PurchaseEvent extends Equatable {
  const PurchaseEvent();
  @override
  List<Object?> get props => [];
}

class LoadPurchases extends PurchaseEvent {
  const LoadPurchases();
}

class CreatePurchase extends PurchaseEvent {
  final int? supplierId;
  final String status; // 'paid'|'unpaid'|'credited'
  final double? paidAmount;
  final String? notes;

  // items: [{product_id:int, quantity:int, price_per_unit:double}]
  final List<Map<String, dynamic>> items;

  const CreatePurchase({
    required this.items,
    this.supplierId,
    this.status = 'unpaid',
    this.paidAmount,
    this.notes,
  });

  @override
  List<Object?> get props => [supplierId, status, paidAmount, items, notes];
}