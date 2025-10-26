import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/expenses/bloc/expense_event.dart';
import 'package:sales_app/features/expenses/bloc/expense_state.dart';
import 'package:sales_app/features/expenses/services/expense_services.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseService service;

  ExpenseBloc({required this.service}) : super(ExpensesInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<LoadExpenseDetails>(_onLoadExpenseDetails);
    on<CreateExpenseEvent>(_onCreateExpense);
  }

  String _friendly(Object e) {
    final t = e.toString();
    if (t.contains('Failed to load')) {
      return "We couldn't load expenses. Please try again.";
    }
    if (t.contains('Failed to create')) {
      return "We couldn't save your expense. Please try again.";
    }
    return "We couldn't complete the request. Please try again.";
    }

  Future<void> _onLoadExpenses(LoadExpenses event, Emitter<ExpenseState> emit) async {
    try {
      emit(ExpensesLoading());
      final list = await service.getExpenses();
      emit(ExpensesLoaded(list));
    } catch (e) {
      emit(ExpensesError(_friendly(e)));
    }
  }

  Future<void> _onLoadExpenseDetails(LoadExpenseDetails event, Emitter<ExpenseState> emit) async {
    try {
      emit(ExpensesLoading());
      final item = await service.getExpense(event.expenseId);
      emit(ExpenseDetailsLoaded(item));
    } catch (e) {
      emit(ExpensesError(_friendly(e)));
    }
  }

  Future<void> _onCreateExpense(CreateExpenseEvent event, Emitter<ExpenseState> emit) async {
    try {
      await service.createExpense(
        description: event.description,
        amount: event.amount,
        dateIncurred: event.dateIncurred,
      );
      emit(const ExpenseOperationSuccess('Expense recorded successfully.'));
      add(const LoadExpenses());
    } catch (e) {
      emit(ExpensesError(_friendly(e)));
    }
  }
}