import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/features/expenses/bloc/expense_bloc.dart';
import 'package:sales_app/features/expenses/bloc/expense_event.dart';
import 'package:sales_app/features/expenses/bloc/expense_state.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _date;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: _date ?? now,
      helpText: 'Select date incurred',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _date == null) {
      if (_date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose the date the expense was incurred.')),
        );
      }
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    context.read<ExpenseBloc>().add(CreateExpenseEvent(
          description: _descCtrl.text.trim(),
          amount: amount,
          dateIncurred: _date!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date != null ? DateFormat.yMMMd().format(_date!) : 'Pick date';

    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listenWhen: (p, c) => p is ExpenseOperationSuccess || p is ExpensesError || c is ExpenseOperationSuccess || c is ExpensesError,
      listener: (context, state) {
        if (state is ExpenseOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.of(context).pop(true);
        }
        if (state is ExpensesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final submitting = state is ExpensesLoading;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text('Add Expense', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Office supplies',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Please enter at least 3 characters.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g. 25.50',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').trim());
                    if (val == null || val <= 0) return 'Please enter a valid amount greater than 0.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(dateLabel),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: submitting ? null : _submit,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: submitting
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Expense', key: ValueKey('save')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}