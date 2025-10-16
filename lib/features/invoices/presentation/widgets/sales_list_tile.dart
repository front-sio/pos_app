import 'package:flutter/material.dart';
import 'package:sales_app/config/config.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';
import 'package:sales_app/features/invoices/services/invoice_services.dart';

class SalesListTile extends StatefulWidget {
  final int saleId;
  final int customerId;
  final double totalAmount;
  final DateTime soldAt;
  final VoidCallback? onTap;

  const SalesListTile({
    super.key,
    required this.saleId,
    required this.customerId,
    required this.totalAmount,
    required this.soldAt,
    this.onTap,
  });

  @override
  State<SalesListTile> createState() => _SalesListTileState();
}

class _SalesListTileState extends State<SalesListTile> {
  late final InvoiceService _invoiceService;
  Invoice? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService(baseUrl: AppConfig.baseUrl); // FIX: pass baseUrl
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // FIX: use a defined method in service
      _invoice = await _invoiceService.getInvoiceBySale(widget.saleId);
    } catch (_) {
      _invoice = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _invoice == null
        ? Colors.orange
        : (_invoice!.status.toLowerCase() == 'paid' || _invoice!.status.toLowerCase() == 'full'
            ? AppColors.kSuccess
            : AppColors.kWarning);

    return ListTile(
      onTap: widget.onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12), // FIX: replace withOpacity
        child: Icon(Icons.receipt_long, color: color),
      ),
      title: Text('Sale #${widget.saleId} • Customer #${widget.customerId}'),
      subtitle: Text('Total: \$${widget.totalAmount.toStringAsFixed(2)} • ${widget.soldAt.toLocal()}'),
      trailing: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _invoice == null
              ? Chip(
                  label: const Text('NO INVOICE'),
                  backgroundColor: Colors.orange.withValues(alpha: 0.12), // FIX: replace withOpacity
                  labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                )
              : Chip(
                  label: Text(_invoice!.status.toUpperCase()),
                  backgroundColor: color.withValues(alpha: 0.12), // FIX
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
    );
  }
}