import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/categories/bloc/category_event.dart';
import 'package:sales_app/features/categories/bloc/category_state.dart';
import 'package:sales_app/features/categories/services/category_service.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryService service;

  CategoryBloc({required this.service}) : super(CategoryState.initial()) {
    on<LoadCategories>(_onLoad);
    on<RefreshCategories>(_onLoad);
    on<CreateCategory>(_onCreate);
    on<DeleteCategory>(_onDelete);
  }

  Future<void> _onLoad(CategoryEvent event, Emitter<CategoryState> emit) async {
    emit(state.copyWith(loading: true, error: ''));
    try {
      final list = await service.getCategories();
      emit(state.copyWith(loading: false, items: list));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onCreate(CreateCategory event, Emitter<CategoryState> emit) async {
    emit(state.copyWith(creating: true, error: ''));
    try {
      await service.createCategory(event.name);
      final list = await service.getCategories();
      emit(state.copyWith(creating: false, items: list));
    } catch (e) {
      emit(state.copyWith(creating: false, error: e.toString()));
    }
  }

  Future<void> _onDelete(DeleteCategory event, Emitter<CategoryState> emit) async {
    emit(state.copyWith(deletingIdInProgress: true, error: ''));
    try {
      await service.deleteCategory(event.id);
      final list = await service.getCategories();
      emit(state.copyWith(deletingIdInProgress: false, items: list));
    } catch (e) {
      emit(state.copyWith(deletingIdInProgress: false, error: e.toString()));
    }
  }
}