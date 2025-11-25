import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final double? totalPurchases;
  final String? address;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.totalPurchases,
    this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    int _int(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '0') ?? 0;
    return Customer(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      totalPurchases: json['totalPurchases'] != null ? (json['totalPurchases'] as num).toDouble() : null,
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'name': name,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };

  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    double? totalPurchases,
    String? address,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, totalPurchases, address];
}