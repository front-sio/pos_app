import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/customers/bloc/customer_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';

enum CustomerOverlayMode { create, view, edit, deleteConfirm }

class CustomerOverlayScreen extends StatefulWidget {
  final Customer? customer;
  final CustomerOverlayMode mode;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const CustomerOverlayScreen({
    super.key,
    required this.customer,
    required this.mode,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<CustomerOverlayScreen> createState() => _CustomerOverlayScreenState();
}

class _CustomerOverlayScreenState extends State<CustomerOverlayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null && widget.mode != CustomerOverlayMode.create) {
      _nameCtrl.text = widget.customer!.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? cs.error : cs.primary),
    );
  }

  String _titleForMode(CustomerOverlayMode mode) {
    switch (mode) {
      case CustomerOverlayMode.create:
        return 'Add Customer';
      case CustomerOverlayMode.view:
        return 'Customer Details';
      case CustomerOverlayMode.edit:
        return 'Edit Customer';
      case CustomerOverlayMode.deleteConfirm:
        return 'Delete Customer';
    }
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
        title: Text(_titleForMode(widget.mode)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
            tooltip: 'Close',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.mode) {
      case CustomerOverlayMode.create:
        return _buildCreateOrEdit(isCreate: true);
      case CustomerOverlayMode.view:
        return _buildView();
      case CustomerOverlayMode.edit:
        return _buildCreateOrEdit(isCreate: false);
      case CustomerOverlayMode.deleteConfirm:
        return _buildDelete();
    }
  }

  Widget _buildView() {
    final c = widget.customer!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: CircleAvatar(
            child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?'),
          ),
          title: Text(c.name, style: theme.textTheme.titleLarge),
        ),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isCreate ? 'Add Customer' : 'Edit ${widget.customer?.name ?? ""}',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.largePadding),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Customer Name*',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'This field cannot be empty';
              return null;
            },
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
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
    final name = widget.customer?.name ?? 'this customer';
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
          'Are you sure you want to delete this customer? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.largePadding),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitCreate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CustomerBloc>().add(AddCustomer(_nameCtrl.text.trim()));
    _snack('Creating customer...');
    widget.onSaved?.call();
  }

  Future<void> _submitEdit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = widget.customer!.id;
    context.read<CustomerBloc>().add(UpdateCustomerEvent(id, _nameCtrl.text.trim()));
    _snack('Customer updated');
    widget.onSaved?.call();
  }

  void _confirmDelete() {
    final id = widget.customer!.id;
    context.read<CustomerBloc>().add(DeleteCustomerEvent(id));
    _snack('Customer deleted');
    widget.onSaved?.call();
  }
}