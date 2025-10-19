import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final int userId;
  final Map<String, dynamic> payload;
  UpdateProfile(this.userId, this.payload);
  @override
  List<Object?> get props => [userId, payload];
}

class RequestAccountDeletion extends ProfileEvent {
  final int userId;
  RequestAccountDeletion(this.userId);
  @override
  List<Object?> get props => [userId];
}