import 'package:equatable/equatable.dart';
import 'package:sales_app/features/categories/data/category_model.dart';

class CategoryState extends Equatable {
  final bool loading;
  final List<Category> items;
  final String error;
  final bool creating;
  final bool deletingIdInProgress;

  const CategoryState({
    required this.loading,
    required this.items,
    required this.error,
    required this.creating,
    required this.deletingIdInProgress,
  });

  factory CategoryState.initial() => const CategoryState(
        loading: false,
        items: <Category>[],
        error: '',
        creating: false,
        deletingIdInProgress: false,
      );

  CategoryState copyWith({
    bool? loading,
    List<Category>? items,
    String? error,
    bool? creating,
    bool? deletingIdInProgress,
  }) {
    return CategoryState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error ?? this.error,
      creating: creating ?? this.creating,
      deletingIdInProgress: deletingIdInProgress ?? this.deletingIdInProgress,
    );
  }

  @override
  List<Object?> get props => [loading, items, error, creating, deletingIdInProgress];
}