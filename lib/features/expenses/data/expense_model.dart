import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final int id;
  final String description;
  final double amount;
  final DateTime dateIncurred;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.dateIncurred,
  });

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _asDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      // Handle date strings in various formats
      if (v.length == 10) {
        // Format: "2025-12-06"
        return DateTime.parse('${v}T00:00:00.000');
      }
      // Try standard ISO format
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: _asInt(json['id']),
      description: (json['description'] ?? '').toString(),
      amount: _asDouble(json['amount']),
      dateIncurred: _asDate(json['date_incurred'] ?? json['dateIncurred']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date_incurred': dateIncurred.toIso8601String().split('T').first,
      };

  @override
  List<Object?> get props => [id, description, amount, dateIncurred];
}
