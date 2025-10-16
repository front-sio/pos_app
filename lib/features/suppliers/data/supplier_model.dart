import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    DateTime _dt(dynamic v) {
      final s = v?.toString();
      return DateTime.tryParse(s ?? '') ?? DateTime.now();
    }

    int _int(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '0') ?? 0;

    return Supplier(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      description: json['description']?.toString(),
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (description != null) 'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, phone, email, address, description, createdAt, updatedAt];
}