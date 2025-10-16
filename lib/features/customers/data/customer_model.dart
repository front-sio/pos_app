import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int id;
  final String name;

  const Customer({
    required this.id,
    required this.name,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    int _int(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '0') ?? 0;
    return Customer(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toCreatePayload() => {'name': name};

  @override
  List<Object?> get props => [id, name];
}