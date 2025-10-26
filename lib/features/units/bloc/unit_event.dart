import 'package:equatable/equatable.dart';

abstract class UnitEvent extends Equatable {
  const UnitEvent();
  @override
  List<Object?> get props => [];
}

class LoadUnits extends UnitEvent {
  const LoadUnits();
}

class CreateUnit extends UnitEvent {
  final String name;
  const CreateUnit(this.name);
  @override
  List<Object?> get props => [name];
}

class DeleteUnit extends UnitEvent {
  final int id;
  const DeleteUnit(this.id);
  @override
  List<Object?> get props => [id];
}

class RefreshUnits extends UnitEvent {
  const RefreshUnits();
}