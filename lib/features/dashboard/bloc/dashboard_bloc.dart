import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/dashboard/bloc/dashboard_event.dart';
import 'package:sales_app/features/dashboard/bloc/dashboard_state.dart';
import 'package:sales_app/features/dashboard/services/dashboard_service.dart';
import 'package:sales_app/utils/api_error_handler.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService service;

  DashboardBloc({required this.service}) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onRefresh);
  }

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) async {
    try {
      emit(DashboardLoading());
      final data = await service.fetch();
      emit(DashboardLoaded(data));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(DashboardError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onRefresh(RefreshDashboard event, Emitter<DashboardState> emit) async {
    try {
      final data = await service.fetch();
      emit(DashboardLoaded(data));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(DashboardError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }
}