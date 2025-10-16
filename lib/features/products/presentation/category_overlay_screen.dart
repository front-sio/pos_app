import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/products/data/category_model.dart';
import 'package:sales_app/features/products/services/product_service.dart';

enum CategoryOverlayMode { create, view, edit, deleteConfirm }

class CategoryOverlayScreen extends StatefulWidget {
  final CategoryModel? category;
  final CategoryOverlayMode mode;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const CategoryOverlayScreen({
    super.key,
    required this.category,
    required this.mode,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<CategoryOverlayScreen> createState() => _CategoryOverlayScreenState();
}

class _CategoryOverlayScreenState extends State<CategoryOverlayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null && widget.mode != CategoryOverlayMode.create) {
      _nameCtrl.text = widget.category!.name;
      _descCtrl.text = widget.category!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _title(CategoryOverlayMode m) {
    switch (m) {
      case CategoryOverlayMode.create:
        return 'Add Category';
      case CategoryOverlayMode.view:
        return 'Category Details';
      case CategoryOverlayMode.edit:
        return 'Edit Category';
      case CategoryOverlayMode.deleteConfirm:
        return 'Delete Category';
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
      case CategoryOverlayMode.create:
        return _form(isCreate: true);
      case CategoryOverlayMode.view:
        return _view();
      case CategoryOverlayMode.edit:
        return _form(isCreate: false);
      case CategoryOverlayMode.deleteConfirm:
        return _delete();
    }
  }

  Widget _view() {
    final c = widget.category!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
          title: Text(c.name, style: theme.textTheme.titleLarge),
          subtitle: Text(c.description ?? 'No description'),
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
        Text(isCreate ? 'Add Category' : 'Edit ${widget.category?.name ?? ""}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.largePadding),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category Name*',
                  prefixIcon: Icon(Icons.category_outlined),
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
    final name = widget.category?.name ?? 'this category';
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
        Text('Are you sure you want to delete this category?', style: theme.textTheme.bodyMedium),
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
      await service.createCategory(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      _snack('Category created');
      widget.onSaved?.call();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _update() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final id = widget.category!.id;
      final service = context.read<ProductService>();
      await service.updateCategory(
        id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      _snack('Category updated');
      widget.onSaved?.call();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _remove() async {
    try {
      final id = widget.category!.id;
      final service = context.read<ProductService>();
      await service.deleteCategory(id);
      _snack('Category deleted');
      widget.onSaved?.call();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }
}