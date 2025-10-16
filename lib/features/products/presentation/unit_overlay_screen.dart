import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/data/unit_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';

enum UnitOverlayMode { create, view, edit, deleteConfirm }

class UnitOverlayScreen extends StatefulWidget {
  final UnitModel? unit;
  final UnitOverlayMode mode;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const UnitOverlayScreen({
    super.key,
    required this.unit,
    required this.mode,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<UnitOverlayScreen> createState() => _UnitOverlayScreenState();
}

class _UnitOverlayScreenState extends State<UnitOverlayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.unit != null && widget.mode != UnitOverlayMode.create) {
      _nameCtrl.text = widget.unit!.name;
      _descCtrl.text = widget.unit!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _title(UnitOverlayMode m) {
    switch (m) {
      case UnitOverlayMode.create:
        return 'Add Unit';
      case UnitOverlayMode.view:
        return 'Unit Details';
      case UnitOverlayMode.edit:
        return 'Edit Unit';
      case UnitOverlayMode.deleteConfirm:
        return 'Delete Unit';
    }
  }

  void _snack(String msg, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? cs.error : cs.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: Text(_title(widget.mode)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    switch (widget.mode) {
      case UnitOverlayMode.create:
        return _form(isCreate: true);
      case UnitOverlayMode.view:
        return _view();
      case UnitOverlayMode.edit:
        return _form(isCreate: false);
      case UnitOverlayMode.deleteConfirm:
        return _delete();
    }
  }

  Widget _view() {
    final u = widget.unit!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: CircleAvatar(child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?')),
          title: Text(u.name, style: theme.textTheme.titleLarge),
          subtitle: Text(u.description ?? 'No description'),
        ),
        const SizedBox(height: AppSizes.largePadding),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(onPressed: widget.onCancel, child: const Text('Close')),
        ),
      ],
    );
  }

  Widget _form({required bool isCreate}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isCreate ? 'Add Unit' : 'Edit ${widget.unit?.name ?? ""}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.largePadding),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit Name*',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'This field cannot be empty' : null,
                onTap: () => HapticFeedback.lightImpact(),
              ),
              const SizedBox(height: AppSizes.padding),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel'))),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isCreate ? _create : _update,
                icon: Icon(isCreate ? Icons.add : Icons.save),
                label: Text(isCreate ? 'Create' : 'Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _delete() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = widget.unit?.name ?? 'this unit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Delete $name',
                style: theme.textTheme.titleLarge?.copyWith(color: cs.error, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: AppSizes.padding),
        Text('Are you sure you want to delete this unit?', style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel'))),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _remove,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final service = context.read<ProductService>();
      await service.createUnit(name: _nameCtrl.text.trim(), description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim());
      _snack('Unit created');
      widget.onSaved?.call();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _update() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final id = widget.unit!.id;
      final service = context.read<ProductService>();
      await service.updateUnit(
        id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      _snack('Unit updated');
      widget.onSaved?.call();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _remove() async {
    try {
      final id = widget.unit!.id;
      final service = context.read<ProductService>();
      await service.deleteUnit(id);
      _snack('Unit deleted');
      widget.onSaved?.call();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }
}