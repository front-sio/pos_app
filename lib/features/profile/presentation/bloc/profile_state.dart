import 'package:equatable/equatable.dart';
import 'package:sales_app/features/users/models/user_model.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileUpdated extends ProfileState {
  final String message;
  ProfileUpdated(this.message);
  @override
  List<Object?> get props => [message];
}

class ProfileError extends ProfileState {
  final String error;
  ProfileError(this.error);
  @override
  List<Object?> get props => [error];
}