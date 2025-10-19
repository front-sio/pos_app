import 'package:flutter_bloc/flutter_bloc.dart';
import 'reports_event.dart';
import 'reports_state.dart';
import 'package:sales_app/features/reports/repository/reports_repository.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository repository;

  ReportsBloc({required this.repository}) : super(ReportsInitial()) {
    on<LoadDailyReport>(_onLoadDailyReport);
    on<LoadMonthlyReport>(_onLoadMonthlyReport);
    on<LoadInventoryReport>(_onLoadInventoryReport);
    on<LoadFinancialReport>(_onLoadFinancialReport);
    on<LoadCustomersReport>(_onLoadCustomersReport);
  }

  Future<void> _onLoadDailyReport(LoadDailyReport event, Emitter<ReportsState> emit) async {
    try {
      emit(ReportsLoading());
      final report = await repository.getDailyReport(event.date);
      emit(SalesReportLoaded(report));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadMonthlyReport(LoadMonthlyReport event, Emitter<ReportsState> emit) async {
    try {
      emit(ReportsLoading());
      final report = await repository.getMonthlyReport(event.year, event.month);
      emit(SalesReportLoaded(report));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadInventoryReport(LoadInventoryReport event, Emitter<ReportsState> emit) async {
    try {
      emit(ReportsLoading());
      final report = await repository.getInventoryReport(threshold: event.threshold);
      emit(InventoryReportLoaded(report));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadFinancialReport(LoadFinancialReport event, Emitter<ReportsState> emit) async {
    try {
      emit(ReportsLoading());
      final report = await repository.getFinancialReport(event.year, event.month);
      emit(FinancialReportLoaded(report));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadCustomersReport(LoadCustomersReport event, Emitter<ReportsState> emit) async {
    try {
      emit(ReportsLoading());
      final report = await repository.getCustomersReport(event.year, event.month);
      emit(CustomersReportLoaded(report));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }
}