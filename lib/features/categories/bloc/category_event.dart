import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

class CreateCategory extends CategoryEvent {
  final String name;
  const CreateCategory(this.name);
  @override
  List<Object?> get props => [name];
}

class DeleteCategory extends CategoryEvent {
  final int id;
  const DeleteCategory(this.id);
  @override
  List<Object?> get props => [id];
}

class RefreshCategories extends CategoryEvent {
  const RefreshCategories();
}