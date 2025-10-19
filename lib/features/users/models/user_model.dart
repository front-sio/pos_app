import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? gender;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final List<int> roles;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      gender: json['gender'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
    );
  }
}