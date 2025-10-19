import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String identifier; // username or email
  final String password;

  LoginRequested(this.identifier, this.password);

  @override
  List<Object?> get props => [identifier, password];
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String password;

  RegisterRequested(this.username, this.email, this.firstName, this.lastName, this.gender, this.password);

  @override
  List<Object?> get props => [username, email, firstName, lastName, gender, password];
}

class AppStarted extends AuthEvent {}

class LogoutRequested extends AuthEvent {}