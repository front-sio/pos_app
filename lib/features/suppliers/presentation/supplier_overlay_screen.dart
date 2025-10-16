import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_bloc.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_event.dart';
import 'package:sales_app/features/suppliers/data/supplier_model.dart';
import 'package:sales_app/utils/responsive.dart';

enum SupplierOverlayMode { create, view, edit, deleteConfirm }

class SupplierOverlayScreen extends StatefulWidget {
  final Supplier? supplier;
  final SupplierOverlayMode mode;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const SupplierOverlayScreen({
    super.key,
    required this.supplier,
    required this.mode,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<SupplierOverlayScreen> createState() => _SupplierOverlayScreenState();
}

class _SupplierOverlayScreenState extends State<SupplierOverlayScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null && widget.mode != SupplierOverlayMode.create) {
      final s = widget.supplier!;
      _nameCtrl.text = s.name;
      _phoneCtrl.text = s.phone ?? '';
      _emailCtrl.text = s.email ?? '';
      _addressCtrl.text = s.address ?? '';
      _descriptionCtrl.text = s.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? cs.error : cs.primary),
    );
  }

  String _titleForMode(SupplierOverlayMode mode) {
    switch (mode) {
      case SupplierOverlayMode.create:
        return 'Add Supplier';
      case SupplierOverlayMode.view:
        return 'Supplier Details';
      case SupplierOverlayMode.edit:
        return 'Edit Supplier';
      case SupplierOverlayMode.deleteConfirm:
        return 'Delete Supplier';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSmall = MediaQuery.of(context).size.width < AppSizes.mobileBreakpoint;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: Text(_titleForMode(widget.mode)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
            tooltip: 'Close',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 2),
        child: Container(
          padding: EdgeInsets.all(isSmall ? AppSizes.padding : AppSizes.padding * 1.5),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(color: cs.outlineVariant, width: 1.2),
            boxShadow: [
              if (theme.brightness == Brightness.light)
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.mode) {
      case SupplierOverlayMode.create:
        return _buildCreateOrEdit(isCreate: true);
      case SupplierOverlayMode.view:
        return _buildView();
      case SupplierOverlayMode.edit:
        return _buildCreateOrEdit(isCreate: false);
      case SupplierOverlayMode.deleteConfirm:
        return _buildDelete();
    }
  }

  Widget _buildView() {
    final s = widget.supplier!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget item(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary.withOpacity(0.1),
              child: Icon(Icons.store_mall_directory_outlined, color: cs.primary),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: Text(
                s.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.largePadding),
        item('Phone', s.phone ?? 'N/A'),
        item('Email', s.email ?? 'N/A'),
        item('Address', s.address ?? 'N/A'),
        item('Description', s.description ?? 'N/A'),
        const SizedBox(height: AppSizes.largePadding),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: widget.onCancel,
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateOrEdit({required bool isCreate}) {
    final isDesktop = Responsive.isDesktop(context);

    Widget twoCol() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                _inputRequired(_nameCtrl, 'Supplier Name*', Icons.store_mall_directory_outlined, validator: _required),
                const SizedBox(height: AppSizes.padding),
                _input(_phoneCtrl, 'Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: AppSizes.padding),
                _input(_emailCtrl, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              ]),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: Column(children: [
                _input(_addressCtrl, 'Address', Icons.location_on_outlined, maxLines: 2),
                const SizedBox(height: AppSizes.padding),
                _input(_descriptionCtrl, 'Description', Icons.description_outlined, maxLines: 3),
              ]),
            ),
          ],
        );

    Widget oneCol() => Column(children: [
          _inputRequired(_nameCtrl, 'Supplier Name*', Icons.store_mall_directory_outlined, validator: _required),
          const SizedBox(height: AppSizes.padding),
          _input(_phoneCtrl, 'Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: AppSizes.padding),
          _input(_emailCtrl, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: AppSizes.padding),
          _input(_addressCtrl, 'Address', Icons.location_on_outlined, maxLines: 2),
          const SizedBox(height: AppSizes.padding),
          _input(_descriptionCtrl, 'Description', Icons.description_outlined, maxLines: 3),
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isCreate ? 'Add Supplier' : 'Edit ${widget.supplier?.name ?? ""}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.largePadding),
        Form(key: _formKey, child: isDesktop ? twoCol() : oneCol()),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel'))),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isCreate ? _submitCreate : _submitEdit,
                icon: Icon(isCreate ? Icons.add : Icons.save),
                label: Text(isCreate ? 'Create' : 'Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDelete() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = widget.supplier?.name ?? 'this supplier';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delete $name',
              style: theme.textTheme.titleLarge?.copyWith(color: cs.error, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        const SizedBox(height: AppSizes.padding),
        Text(
          'Are you sure you want to delete this supplier? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel'))),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _confirmDelete,
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

  Widget _input(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
      ),
    );
  }

  Widget _inputRequired(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
      ),
      onTap: () => HapticFeedback.lightImpact(),
    );
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field cannot be empty';
    return null;
  }

  Future<void> _submitCreate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
    };
    context.read<SupplierBloc>().add(AddSupplier(data));
    _snack('Creating supplier...');
    widget.onSaved?.call();
  }

  Future<void> _submitEdit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = widget.supplier!.id;
    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
    };
    context.read<SupplierBloc>().add(UpdateSupplierEvent(id, data));
    _snack('Supplier updated');
    widget.onSaved?.call();
  }

  void _confirmDelete() {
    final id = widget.supplier!.id;
    context.read<SupplierBloc>().add(DeleteSupplierEvent(id));
    _snack('Supplier deleted');
    widget.onSaved?.call();
  }
}