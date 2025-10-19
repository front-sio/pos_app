import 'package:flutter/foundation.dart';

@immutable
class RoleModel {
  final int id;
  final String name;
  final String? description;

  const RoleModel({required this.id, required this.name, required this.description});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

@immutable
class PermissionModel {
  final int id;
  final String name;
  final String? description;

  const PermissionModel({required this.id, required this.name, required this.description});

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}