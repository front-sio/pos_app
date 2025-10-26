import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/units/bloc/unit_bloc.dart';
import 'package:sales_app/features/units/bloc/unit_event.dart';
import 'package:sales_app/features/units/bloc/unit_state.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UnitBloc>().add(const LoadUnits());
  }

  Future<void> _promptAdd() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Unit'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
        return;
      }
      context.read<UnitBloc>().add(CreateUnit(name));
    }
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
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
      context.read<UnitBloc>().add(DeleteUnit(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context.read<UnitBloc>().add(const RefreshUnits()),
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
      body: BlocConsumer<UnitBloc, UnitState>(
        listenWhen: (a, b) => b.error.isNotEmpty == true,
        listener: (context, state) {
          if (state.error.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.kError),
            );
          }
        },
        builder: (context, state) {
          final q = _searchCtrl.text.trim().toLowerCase();
          final list = q.isEmpty
              ? state.items
              : state.items.where((u) => u.name.toLowerCase().contains(q) || u.id.toString() == q).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search unit by name or #id',
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
                    ? const Center(child: Text('No units'))
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
                                child: Icon(Icons.straighten, color: cs.primary),
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