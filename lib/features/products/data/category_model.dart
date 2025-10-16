import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int _int(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '0') ?? 0;

    return CategoryModel(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'name': name,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => [id, name, description, createdAt, updatedAt];
}