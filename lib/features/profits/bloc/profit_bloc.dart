import 'package:flutter/material.dart'; // <-- Needed for DateTimeRange
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/profits/bloc/profit_event.dart';
import 'package:sales_app/features/profits/bloc/profit_state.dart';
import 'package:sales_app/features/profits/services/profit_services.dart';

class ProfitBloc extends Bloc<ProfitEvent, ProfitState> {
  final ProfitService service;

  ProfitBloc({required this.service}) : super(ProfitInitial()) {
    on<LoadProfit>(_onLoad);
    on<ChangePeriod>(_onChangePeriod);
    on<ChangeView>(_onChangeView);
    on<RefreshProfit>(_onRefresh);
  }

  DateTimeRange _rangeForPeriod(String period, {DateTime? from, DateTime? to}) {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case 'This Week':
        final weekday = now.weekday; // Mon=1..Sun=7
        final start =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        return DateTimeRange(start: start, end: now);
      case 'This Month':
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      case 'Last 3 Months':
        final start = DateTime(now.year, now.month - 2, 1);
        return DateTimeRange(start: start, end: now);
      case 'Custom Range':
        if (from != null && to != null) return DateTimeRange(start: from, end: to);
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  Future<void> _load(
    String period,
    String view,
    Emitter<ProfitState> emit, {
    DateTime? from,
    DateTime? to,
  }) async {
    emit(ProfitLoading());
    try {
      final range = _rangeForPeriod(period, from: from, to: to);
      final summary = await service.getSummary(from: range.start, to: range.end);
      final timeline =
          await service.getTimeline(view: view.toLowerCase(), from: range.start, to: range.end);
      final txs = await service.getTransactions(limit: 10);
      emit(ProfitLoaded(
        period: period,
        view: view,
        from: range.start,
        to: range.end,
        summary: summary,
        timeline: timeline,
        transactions: txs,
      ));
    } catch (e) {
      emit(ProfitError(e.toString()));
    }
  }

  Future<void> _onLoad(LoadProfit event, Emitter<ProfitState> emit) async {
    await _load(event.period, event.view, emit, from: event.from, to: event.to);
  }

  Future<void> _onChangePeriod(ChangePeriod event, Emitter<ProfitState> emit) async {
    final currentView = state is ProfitLoaded ? (state as ProfitLoaded).view : 'Daily';
    await _load(event.period, currentView, emit);
  }

  Future<void> _onChangeView(ChangeView event, Emitter<ProfitState> emit) async {
    final current = state is ProfitLoaded ? (state as ProfitLoaded) : null;
    final period = current?.period ?? 'This Month';
    await _load(period, event.view, emit, from: current?.from, to: current?.to);
  }

  Future<void> _onRefresh(RefreshProfit event, Emitter<ProfitState> emit) async {
    final current = state is ProfitLoaded ? (state as ProfitLoaded) : null;
    final period = current?.period ?? 'This Month';
    final view = current?.view ?? 'Daily';
    await _load(period, view, emit, from: current?.from, to: current?.to);
  }
}