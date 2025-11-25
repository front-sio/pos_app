import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_app/config/config.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';
import 'package:sales_app/features/customers/services/customer_services.dart';

class CustomerSelectorSheet extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final bool isLoading;

  const CustomerSelectorSheet({
    super.key,
    required this.customers,
    this.selectedCustomer,
    this.isLoading = false,
  });

  @override
  State<CustomerSelectorSheet> createState() => _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState extends State<CustomerSelectorSheet> {
  final _searchController = TextEditingController();
  late List<Customer> _filtered;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _filtered = [...widget.customers];
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? [...widget.customers]
          : widget.customers.where((c) => c.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _openAddCustomer() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final created = await showModalBottomSheet<Customer>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const _AddCustomerSheet(),
      );
      if (created != null && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, created);
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Row(
                  children: [
                    const Icon(Icons.person_search, size: 24),
                    const SizedBox(width: 12),
                    Text('Select Customer', style: Theme.of(context).textTheme.titleLarge),
                    if (widget.isLoading) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _creating ? null : _openAddCustomer,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text("Add new"),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: widget.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? _EmptyState(onAdd: _creating ? null : _openAddCustomer)
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final customer = _filtered[index];
                              final isSelected = widget.selectedCustomer?.id == customer.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.kPrimary.withValues(alpha: 0.1),
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                    style: TextStyle(color: AppColors.kPrimary),
                                  ),
                                ),
                                title: Text(customer.name, overflow: TextOverflow.ellipsis),
                                subtitle: Text('ID: ${customer.id}'),
                                selected: isSelected,
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: AppColors.kPrimary)
                                    : null,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context, customer);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  const _EmptyState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 48, color: cs.outline),
          const SizedBox(height: 12),
          Text('No customers found', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Try a different search or add a new customer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.largePadding),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add new customer'),
          ),
        ],
      ),
    );
  }
}

class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final svc = CustomerService(baseUrl: AppConfig.baseUrl);
      final created = await svc.createCustomer(_nameCtrl.text.trim());
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, created);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Customer', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.padding),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name*',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'This field cannot be empty';
                    return null;
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.padding),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.padding),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.save),
                      label: _submitting ? const Text('Saving...') : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}