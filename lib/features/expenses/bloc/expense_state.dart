import 'package:equatable/equatable.dart';
import 'package:sales_app/features/expenses/data/expense_model.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
  @override
  List<Object?> get props => [];
}

class ExpensesInitial extends ExpenseState {}
class ExpensesLoading extends ExpenseState {}

class ExpensesLoaded extends ExpenseState {
  final List<Expense> expenses;
  const ExpensesLoaded(this.expenses);
  @override
  List<Object?> get props => [expenses];
}

class ExpenseDetailsLoaded extends ExpenseState {
  final Expense expense;
  const ExpenseDetailsLoaded(this.expense);
  @override
  List<Object?> get props => [expense];
}

class ExpensesError extends ExpenseState {
  final String message;
  const ExpensesError(this.message);
  @override
  List<Object?> get props => [message];
}

class ExpenseOperationSuccess extends ExpenseState {
  final String message;
  const ExpenseOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}