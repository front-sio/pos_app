import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';

import 'package:sales_app/features/expenses/bloc/expense_bloc.dart';
import 'package:sales_app/features/expenses/bloc/expense_event.dart';
import 'package:sales_app/features/expenses/bloc/expense_state.dart';
import 'package:sales_app/features/expenses/data/expense_model.dart';
import 'package:sales_app/features/expenses/presentation/add_expense_sheet.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchCtrl = TextEditingController();
  List<Expense> _lastKnown = const <Expense>[];

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const LoadExpenses());
  }

  Future<void> _refresh() async {
    context.read<ExpenseBloc>().add(const LoadExpenses());
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  void _openAddExpenseSheet() async {
    final res = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: const AddExpenseSheet(),
      ),
    );
    if (mounted && res == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listenWhen: (a, b) => b is ExpenseOperationSuccess || b is ExpensesError,
      listener: (context, state) {
        if (state is ExpenseOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kSuccess),
          );
        }
        if (state is ExpensesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.kError),
          );
        }
      },
      buildWhen: (a, b) => b is ExpensesLoading || b is ExpensesLoaded || b is ExpensesError,
      builder: (context, state) {
        List<Expense> source = _lastKnown;
        bool showRefreshingBar = false;

        if (state is ExpensesLoaded) {
          source = state.expenses;
          _lastKnown = source;
        } else if (state is ExpensesLoading) {
          if (_lastKnown.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          showRefreshingBar = true;
        } else if (state is ExpensesError) {
          if (_lastKnown.isEmpty) {
            return _TopLevelError(message: state.message, onRetry: _refresh);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.kError),
              );
            });
            source = _lastKnown;
          }
        }

        final q = _searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? [...source]
            : source.where((e) => e.description.toLowerCase().contains(q)).toList();

        filtered.sort((a, b) => b.dateIncurred.compareTo(a.dateIncurred));

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.kPrimary,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search expenses by description',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() => _searchCtrl.clear()),
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.padding),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.padding),
                          child: filtered.isEmpty
                              ? const Center(child: Text('No expenses'))
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
                                  itemBuilder: (_, i) {
                                    final e = filtered[i];
                                    final ago = _timeAgo(e.dateIncurred.toLocal());
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blueGrey.withValues(alpha: 0.1),
                                        child: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                                      ),
                                      title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      subtitle: Text(DateFormat.yMMMEd().format(e.dateIncurred)),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            CurrencyFmt.format(context, e.amount),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(ago, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showRefreshingBar)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton.extended(
                onPressed: _openAddExpenseSheet,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopLevelError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _TopLevelError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: cs.error),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}