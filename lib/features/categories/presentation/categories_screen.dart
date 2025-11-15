import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/categories/bloc/category_bloc.dart';
import 'package:sales_app/features/categories/bloc/category_event.dart';
import 'package:sales_app/features/categories/bloc/category_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  Future<void> _promptAdd() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a category name')),
        );
        return;
      }
      context.read<CategoryBloc>().add(CreateCategory(name));
    }
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.kError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      context.read<CategoryBloc>().add(DeleteCategory(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context.read<CategoryBloc>().add(const RefreshCategories()),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _promptAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: cs.primary,
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listenWhen: (a, b) => b.error.isNotEmpty == true,
        listener: (context, state) {
          if (state.error.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Unable to complete operation. Please try again.'),
                backgroundColor: AppColors.kError,
              ),
            );
          }
        },
        builder: (context, state) {
          final q = _searchCtrl.text.trim().toLowerCase();
          final list = q.isEmpty
              ? state.items
              : state.items.where((c) => c.name.toLowerCase().contains(q) || c.id.toString() == q).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search category by name or #id',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(_searchCtrl.clear),
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (state.loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('No categories'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final it = list[i];
                          return Material(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              leading: CircleAvatar(
                                backgroundColor: cs.primary.withValues(alpha: 0.12),
                                child: Icon(Icons.label, color: cs.primary),
                              ),
                              title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('ID: ${it.id}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: AppColors.kError,
                                onPressed: () => _confirmDelete(it.id, it.name),
                                tooltip: 'Delete',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}