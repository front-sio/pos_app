import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/customers/data/customer_model.dart';

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
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final filtered = _searchController.text.isEmpty
        ? widget.customers
        : widget.customers
            .where((c) => c.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person_search, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Select Customer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.isLoading) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
            
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                onChanged: (_) => setState(() {}),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final customer = filtered[index];
                  final isSelected = widget.selectedCustomer?.id == customer.id;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                      child: Text(
                        customer.name[0].toUpperCase(),
                        style: TextStyle(color: AppColors.kPrimary),
                      ),
                    ),
                    title: Text(customer.name),
                    subtitle: Text('ID: ${customer.id}'),
                    selected: isSelected,
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: AppColors.kPrimary)
                        : null,
                    onTap: () => Navigator.pop(context, customer),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}