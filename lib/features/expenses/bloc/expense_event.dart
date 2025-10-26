import 'package:equatable/equatable.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  const LoadExpenses();
}

class LoadExpenseDetails extends ExpenseEvent {
  final int expenseId;
  const LoadExpenseDetails(this.expenseId);
  @override
  List<Object?> get props => [expenseId];
}

class CreateExpenseEvent extends ExpenseEvent {
  final String description;
  final double amount;
  final DateTime dateIncurred;

  const CreateExpenseEvent({
    required this.description,
    required this.amount,
    required this.dateIncurred,
  });

  @override
  List<Object?> get props => [description, amount, dateIncurred];
}