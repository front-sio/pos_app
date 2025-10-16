class ProductReturn {
  final int id;
  final int saleitemId;
  final int quantityReturned;
  final String? reason;
  final DateTime returnedAt;

  ProductReturn({
    required this.id,
    required this.saleitemId,
    required this.quantityReturned,
    this.reason,
    required this.returnedAt,
  });

  factory ProductReturn.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) {
        final d = DateTime.tryParse(v);
        return d ?? DateTime.now();
      }
      return DateTime.now();
    }

    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return ProductReturn(
      id: _toInt(json["id"]),
      saleitemId: _toInt(json["saleitem_id"]),
      quantityReturned: _toInt(json["quantity_returned"]),
      reason: json["reason"]?.toString(),
      returnedAt: _parseDate(json["returned_at"]),
    );
  }
}