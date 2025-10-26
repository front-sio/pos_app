import 'package:equatable/equatable.dart';
import 'package:sales_app/utils/data/unit_model.dart';

class UnitState extends Equatable {
  final bool loading;
  final List<ProductUnit> items;
  final String error;
  final bool creating;
  final bool deletingIdInProgress;

  const UnitState({
    required this.loading,
    required this.items,
    required this.error,
    required this.creating,
    required this.deletingIdInProgress,
  });

  factory UnitState.initial() => const UnitState(
        loading: false,
        items: <ProductUnit>[],
        error: '',
        creating: false,
        deletingIdInProgress: false,
      );

  UnitState copyWith({
    bool? loading,
    List<ProductUnit>? items,
    String? error,
    bool? creating,
    bool? deletingIdInProgress,
  }) {
    return UnitState(
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