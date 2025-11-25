import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/sales/data/sales_model.dart';


class SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;
  final bool isLoading;

  const SaleCard({
    super.key,
    required this.sale,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoice = sale.invoiceStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sale ID and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sale #${sale.id}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(sale.soldAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${(sale.totalAmount ?? 0).toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (invoice != null) ...[
                        const SizedBox(height: 4),
                        _buildStatusChip(invoice),
                      ],
                    ],
                  ),
                ],
              ),
              
              if (invoice != null && !invoice.isPaid) ...[
                const SizedBox(height: AppSizes.padding),
                LinearProgressIndicator(
                  value: invoice.paidAmount / invoice.totalAmount,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    _getStatusColor(invoice.status),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid: \$${invoice.paidAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Due: \$${invoice.dueAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: AppSizes.padding),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(InvoiceStatus invoice) {
    final color = _getStatusColor(invoice.status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        invoice.status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'credit':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';
  }
}