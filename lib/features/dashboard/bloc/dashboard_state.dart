import 'package:equatable/equatable.dart';
import 'package:sales_app/features/dashboard/data/dashboard_models.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  const DashboardLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class DashboardError extends DashboardState {
  final String message;
  final bool isNetworkError;
  
  const DashboardError(this.message, {this.isNetworkError = false});
  
  @override
  List<Object?> get props => [message, isNetworkError];
}