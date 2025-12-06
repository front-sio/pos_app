class StockTransaction {
  final int id;
  final int productId;
  final int userId;
  final int? supplierId;
  final double amountAdded;
  final double pricePerUnit;
  final double totalCost;
  final DateTime timestamp;
  final String? productName;
  final String? unitName;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.userId,
    required this.supplierId,
    required this.amountAdded,
    required this.pricePerUnit,
    required this.totalCost,
    required this.timestamp,
    this.productName,
    this.unitName,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      userId: json['user_id'] as int,
      supplierId: json['supplier_id'] as int?,
      amountAdded: double.parse(json['amount_added'].toString()),
      pricePerUnit: double.parse(json['price_per_unit'].toString()),
      totalCost: double.parse(json['total_cost'].toString()),
      timestamp: DateTime.parse(json['timestamp'].toString()),
      productName: json['product_name'] as String?,
      unitName: json['unit_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'supplier_id': supplierId,
      'amount_added': amountAdded,
      'price_per_unit': pricePerUnit,
      'total_cost': totalCost,
      'timestamp': timestamp.toIso8601String(),
      'product_name': productName,
      'unit_name': unitName,
    };
  }

  bool get isAddition => amountAdded > 0;
}
