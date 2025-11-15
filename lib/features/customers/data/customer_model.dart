import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String? phone;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    int _int(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '0') ?? 0;
    return Customer(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
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
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone];
}