import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/units/bloc/unit_event.dart';
import 'package:sales_app/features/units/bloc/unit_state.dart';
import 'package:sales_app/features/units/services/unit_services.dart';


class UnitBloc extends Bloc<UnitEvent, UnitState> {
  final UnitService service;

  UnitBloc({required this.service}) : super(UnitState.initial()) {
    on<LoadUnits>(_onLoad);
    on<RefreshUnits>(_onLoad);
    on<CreateUnit>(_onCreate);
    on<DeleteUnit>(_onDelete);
  }

  Future<void> _onLoad(UnitEvent event, Emitter<UnitState> emit) async {
    emit(state.copyWith(loading: true, error: ''));
    try {
      final list = await service.getUnits();
      emit(state.copyWith(loading: false, items: list));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onCreate(CreateUnit event, Emitter<UnitState> emit) async {
    emit(state.copyWith(creating: true, error: ''));
    try {
      await service.createUnit(event.name);
      final list = await service.getUnits();
      emit(state.copyWith(creating: false, items: list));
    } catch (e) {
      emit(state.copyWith(creating: false, error: e.toString()));
    }
  }

  Future<void> _onDelete(DeleteUnit event, Emitter<UnitState> emit) async {
    emit(state.copyWith(deletingIdInProgress: true, error: ''));
    try {
      await service.deleteUnit(event.id);
      final list = await service.getUnits();
      emit(state.copyWith(deletingIdInProgress: false, items: list));
    } catch (e) {
      emit(state.copyWith(deletingIdInProgress: false, error: e.toString()));
    }
  }
}