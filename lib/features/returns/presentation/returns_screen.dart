import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/features/returns/data/return_model.dart';
import 'package:sales_app/features/returns/services/return_service.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _service = ReturnsService();
  late Future<List<ProductReturn>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Returns')),
      body: FutureBuilder<List<ProductReturn>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                snap.error.toString(),
                style: const TextStyle(color: AppColors.kError),
              ),
            );
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return Center(
              child: Text('No returns recorded yet', style: Theme.of(context).textTheme.titleMedium),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = data[i];
                final title = (r.productName != null && r.productName!.trim().isNotEmpty)
                    ? r.productName!
                    : 'Sale item #${r.saleitemId}';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.12),
                      child: const Icon(Icons.undo, color: Colors.orange),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Return #${r.id} • Qty: ${r.quantityReturned} • ${r.reason?.trim().isNotEmpty == true ? r.reason : "No reason"}'),
                    trailing: Text(
                      _format(r.returnedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _format(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
  }
}