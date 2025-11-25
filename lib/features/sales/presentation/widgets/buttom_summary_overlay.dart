import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';
import 'package:sales_app/features/sales/bloc/sales_bloc.dart';
import 'package:sales_app/features/sales/bloc/sales_state.dart';

class BottomSummaryBar extends StatefulWidget {
  final TextEditingController paidAmountCtrl;
  final TextEditingController discountCtrl;
  final double Function(String) computeParseAmount;
  final double Function() computeSubtotalCallback;
  final VoidCallback onCancel;
  final VoidCallback onCheckout;

  // Optional extra rows to render above the action buttons (e.g., taxes, fees)
  final List<Widget> extraRows;

  const BottomSummaryBar({
    super.key,
    required this.paidAmountCtrl,
    required this.discountCtrl,
    required this.computeParseAmount,
    required this.computeSubtotalCallback,
    required this.onCancel,
    required this.onCheckout,
    this.extraRows = const <Widget>[],
  });

  @override
  State<BottomSummaryBar> createState() => _BottomSummaryBarState();
}

class _BottomSummaryBarState extends State<BottomSummaryBar> {
  @override
  void initState() {
    super.initState();
    widget.paidAmountCtrl.addListener(_rebuild);
    widget.discountCtrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.paidAmountCtrl.removeListener(_rebuild);
    widget.discountCtrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, salesState) {
        final subtotal = widget.computeSubtotalCallback();
        final discount = widget.computeParseAmount(widget.discountCtrl.text);
        final total = (subtotal - discount).clamp(0, double.infinity);
        final paidAmount = widget.computeParseAmount(widget.paidAmountCtrl.text);
        final due = (total - paidAmount).clamp(0, double.infinity);

        String fmt(num v) => CurrencyFmt.format(context, v);

        return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Discount Amount',
                      prefixIcon: Icon(Icons.local_offer),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.padding),
                Expanded(
                  child: TextField(
                    controller: widget.paidAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.padding),

            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtotal',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt(subtotal),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.black87,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Discount',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '-${fmt(discount)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.purple,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Due',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt(total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.kPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Any extra rows such as tax, fees, etc.
            if (widget.extraRows.isNotEmpty) ...[
              const SizedBox(height: AppSizes.padding),
              ...widget.extraRows,
            ],

            const SizedBox(height: AppSizes.padding),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSizes.padding),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: widget.onCheckout,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      due <= 0 ? 'Complete Sale' : 'Complete Sale (${CurrencyFmt.format(context, due)})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}