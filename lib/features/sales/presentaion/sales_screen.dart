import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';

// Services and blocs
import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/sales/bloc/sales_bloc.dart';
import 'package:sales_app/features/sales/bloc/sales_event.dart';
import 'package:sales_app/features/sales/bloc/sales_state.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';

// Models
import 'package:sales_app/features/sales/data/sales_model.dart';
import 'package:sales_app/features/sales/data/sale_item.dart';


/// Library-wide helper for relative time (accessible from all classes in this file)
String timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds.abs() < 10) return 'now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks week${weeks > 1 ? 's' : ''} ago';
  }
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  }
  final years = (diff.inDays / 365).floor();
  return '$years year${years > 1 ? 's' : ''} ago';
}

/// Sales screen with:
/// - Status chips: FULL, CREDITED, UNPAID
/// - Returned products badge (sum of quantities returned)
/// - Customer name (not id)
/// - Relative time (now, 2 hours ago, 2 days ago)
/// - Newest first + "NEW SALE" badge for very recent sales
/// - Real-time updates (WebSocket if available, fallback to polling)
class SalesScreen extends StatefulWidget {
  final VoidCallback? onAddNewSale;
  const SalesScreen({Key? key, this.onAddNewSale}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with WidgetsBindingObserver {
  // Caches to avoid refetching on every build
  final Map<int, String> _customerNames = {}; // saleId -> name
  final Map<int, InvoiceStatus?> _invoiceBySale = {}; // saleId -> invoice
  final Map<int, int> _returnedQtyBySale = {}; // saleId -> sum returned qty

  // Real-time
  Timer? _poller;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;

  // UI helpers
  static const Duration kNewSaleWindow = Duration(minutes: 10);
  static const Duration kPollEvery = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<SalesBloc>().add(LoadSales());
    _startRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRealtime();
    super.dispose();
  }

  // Keep polling when app is visible
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRealtime();
    } else if (state == AppLifecycleState.paused) {
      _stopRealtime(); // release socket/timer while in background
    }
  }

  Future<void> _refresh() async {
    context.read<SalesBloc>().add(LoadSales());
    await Future.delayed(const Duration(milliseconds: 150));
  }

  // Realtime: try WebSocket -> fallback to polling
  void _startRealtime() {
    _stopRealtime();

    // Attempt WebSocket. If your gateway exposes one, set it here.
    // We try upgrading baseUrl (http->ws, https->wss) and append /ws/sales
    try {
      final salesService = context.read<SalesService>();
      final base = salesService.baseUrl; // e.g., http://localhost:8080
      final uri = Uri.parse(base);
      final isSecure = uri.scheme == 'https';
      final wsUri = Uri(
        scheme: isSecure ? 'wss' : 'ws',
        host: uri.host,
        port: uri.hasPort ? uri.port : (isSecure ? 443 : 80),
        path: '/ws/sales',
      );
      _ws = WebSocketChannel.connect(wsUri);
      _wsSub = _ws!.stream.listen((msg) {
        if (kDebugMode) debugPrint('[SalesScreen][WS] message: $msg');
        try {
          final data = jsonDecode(msg.toString());
          final type = data['type']?.toString().toLowerCase();
          if (type == 'sale_created' || type == 'sale_updated' || type == 'sales_changed') {
            context.read<SalesBloc>().add(LoadSales());
          }
        } catch (_) {
          // If message shape unknown, just refresh conservatively
          context.read<SalesBloc>().add(LoadSales());
        }
      }, onError: (e) {
        if (kDebugMode) debugPrint('[SalesScreen][WS] error: $e');
        _beginPolling(); // fallback
      }, onDone: () {
        if (kDebugMode) debugPrint('[SalesScreen][WS] closed, fallback to polling');
        _beginPolling(); // fallback when socket closes
      });

      // Also do an initial poll to ensure fresh data
      context.read<SalesBloc>().add(LoadSales());
    } catch (e) {
      if (kDebugMode) debugPrint('[SalesScreen] WS connect failed: $e');
      _beginPolling();
    }
  }

  void _beginPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(kPollEvery, (_) {
      context.read<SalesBloc>().add(LoadSales());
    });
  }

  void _stopRealtime() {
    _poller?.cancel();
    _poller = null;
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;
  }

  Future<_TileData> _loadTileData(Sale sale) async {
    final salesService = context.read<SalesService>();
    final customerService = context.read<CustomerService>();

    // Customer name (cache by sale id)
    String customerName = _customerNames[sale.id] ??
        (sale.customerId != null ? 'Customer #${sale.customerId}' : 'Unknown');

    if (!_customerNames.containsKey(sale.id) && sale.customerId != null && sale.customerId! > 0) {
      try {
        // You may optimize by caching the entire list in CustomerService
        final list = await customerService.getCustomers(page: 1, limit: 1000);
        final found = list.where((c) => c.id == sale.customerId).toList();
        if (found.isNotEmpty) {
          customerName = found.first.name;
          _customerNames[sale.id] = customerName;
        }
      } catch (_) {
        // keep fallback
      }
    }

    // Invoice (cache)
    InvoiceStatus? invoice = _invoiceBySale[sale.id];
    if (invoice == null) {
      try {
        invoice = sale.invoiceStatus ?? await salesService.getInvoiceBySaleId(sale.id);
        _invoiceBySale[sale.id] = invoice;
      } catch (_) {
        // ignore
      }
    }

    // Returns sum qty (cache)
    int returnedQty = _returnedQtyBySale[sale.id] ?? 0;
    if (!_returnedQtyBySale.containsKey(sale.id)) {
      try {
        final returns = await salesService.getReturnsBySaleId(sale.id);
        returnedQty = returns.fold<int>(0, (sum, r) => sum + r.quantityReturned);
        _returnedQtyBySale[sale.id] = returnedQty;
      } catch (_) {
        // ignore
      }
    }

    return _TileData(
      customerName: customerName,
      invoice: invoice,
      returnedQty: returnedQty,
    );
  }

  void _openSaleDetails(Sale sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _SaleDetailsSheet(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          if (state is SalesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SalesError) {
            return Center(child: Text(state.message, style: TextStyle(color: AppColors.kError)));
          }

          List<Sale> sales = (state is SalesLoaded) ? state.sales : <Sale>[];
          if (sales.isEmpty) {
            return Center(
              child: Text("No sales yet", style: theme.textTheme.titleMedium),
            );
          }

          // Sort newest first
          sales = [...sales]..sort((a, b) => b.soldAt.compareTo(a.soldAt));

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.kPrimary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: sales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final sale = sales[i];
                final isNew = DateTime.now().difference(sale.soldAt).abs() <= kNewSaleWindow;
                return FutureBuilder<_TileData>(
                  future: _loadTileData(sale),
                  builder: (context, snap) {
                    final data = snap.data;
                    final invoice = data?.invoice;
                    final returnedQty = data?.returnedQty ?? 0;
                    final customerName = data?.customerName ?? (sale.customerId?.toString() ?? 'Unknown');

                    return Material(
                      color: theme.cardColor,
                      elevation: 1.2,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openSaleDetails(sale),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Leading icon
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.receipt_long, color: AppColors.kPrimary),
                              ),
                              const SizedBox(width: 12),

                              // Main info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title + status chips row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Sale #${sale.id}',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (invoice != null) _statusChip(invoice),
                                        if (isNew) ...[
                                          const SizedBox(width: 6),
                                          _ChipBadge(
                                            text: 'NEW SALE',
                                            foreground: Colors.blue,
                                            background: Colors.blue.withOpacity(0.10),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Customer + time
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 10,
                                      runSpacing: 6,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Text('Customer: $customerName', style: theme.textTheme.bodySmall),
                                          ],
                                        ),
                                        const Text('•'),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Text(timeAgo(sale.soldAt), style: theme.textTheme.bodySmall),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Footer: amount + returns
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '\$${(sale.totalAmount ?? 0).toStringAsFixed(2)}',
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        if (returnedQty > 0)
                                          _ChipBadge(
                                            text: 'Returned $returnedQty',
                                            foreground: Colors.orange,
                                            background: Colors.orange.withOpacity(0.12),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddNewSale,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Sale'),
        backgroundColor: AppColors.kPrimary,
      ),
    );
  }

  // Create a status chip from invoice status
  Widget _statusChip(InvoiceStatus invoice) {
    final s = invoice.status.toLowerCase();
    if (s == 'full' || (invoice.isPaid || (invoice.dueAmount == 0 && invoice.paidAmount >= invoice.totalAmount))) {
      return _ChipBadge(
        text: 'FULL',
        foreground: Colors.green.shade700,
        background: Colors.green.withOpacity(0.12),
      );
    }
    if (s == 'credited' || (invoice.paidAmount > 0 && invoice.dueAmount > 0)) {
      return _ChipBadge(
        text: 'CREDITED',
        foreground: Colors.orange.shade700,
        background: Colors.orange.withOpacity(0.12),
      );
    }
    return _ChipBadge(
      text: 'UNPAID',
      foreground: Colors.red.shade700,
      background: Colors.red.withOpacity(0.12),
    );
  }
}

class _TileData {
  final String customerName;
  final InvoiceStatus? invoice;
  final int returnedQty;

  _TileData({
    required this.customerName,
    required this.invoice,
    required this.returnedQty,
  });
}

class _SaleDetailsSheet extends StatefulWidget {
  final Sale sale;
  const _SaleDetailsSheet({required this.sale});

  @override
  State<_SaleDetailsSheet> createState() => _SaleDetailsSheetState();
}

class _SaleDetailsSheetState extends State<_SaleDetailsSheet> {
  late Sale _sale;

  bool _loading = true;
  String _error = '';
  String _customerName = 'Unknown';
  InvoiceStatus? _invoice;
  final Map<int, String> _productNames = {};
  final Map<int, int> _returnedByItem = {};
  int? _workingItemId;

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
    _loadAuxiliaryData();
  }

  Future<void> _loadAuxiliaryData() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final salesService = context.read<SalesService>();
      // Always fetch full sale w/ items to avoid "0 items"
      final fetched = await salesService.getSaleById(_sale.id);
      if (fetched != null) {
        _sale = fetched;
      }

      // Customer
      final cid = _sale.customerId;
      if (cid != null && cid > 0) {
        try {
          final customerService = context.read<CustomerService>();
          final list = await customerService.getCustomers(page: 1, limit: 1000);
          final found = list.where((c) => c.id == cid).toList();
          if (found.isNotEmpty) _customerName = found.first.name;
        } catch (e) {
          if (kDebugMode) debugPrint('[SaleDetailsSheet] customer fetch warn: $e');
          _customerName = 'Customer #$cid';
        }
      }

      // Product names
      _productNames.clear();
      final productsState = context.read<ProductsBloc>().state;
      if (productsState is ProductsLoaded) {
        for (final item in _sale.items) {
          final p = productsState.products.where((x) => x.id == item.productId).toList();
          _productNames[item.productId] = p.isNotEmpty ? p.first.name : 'Product #${item.productId}';
        }
      } else {
        for (final item in _sale.items) {
          _productNames[item.productId] = 'Product #${item.productId}';
        }
      }

      // Invoice
      _invoice = _sale.invoiceStatus ?? await salesService.getInvoiceBySaleId(_sale.id);

      // Returns aggregation
      _returnedByItem.clear();
      final returns = await salesService.getReturnsBySaleId(_sale.id);
      for (final r in returns) {
        _returnedByItem[r.saleItemId] = (_returnedByItem[r.saleItemId] ?? 0) + r.quantityReturned;
      }
      if (kDebugMode) {
        debugPrint('[SaleDetailsSheet] returns agg: $_returnedByItem');
      }
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('[SaleDetailsSheet] loadAux error: $e');
        debugPrintStack(stackTrace: st);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _sumReturnedAll() => _returnedByItem.values.fold(0, (s, v) => s + v);

  Future<void> _promptReturn(SaleItem item) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot return: missing sale item id')),
      );
      if (kDebugMode) debugPrint('[Return] blocked: missing sale item id for product ${item.productId}');
      return;
    }

    final qtyController = TextEditingController(text: '1');
    final reasonController = TextEditingController();
    final theme = Theme.of(context);
    final int maxQty = item.quantitySold.floor();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many do you want to return?', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Max: $maxQty', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Return')),
        ],
      ),
    );

    if (confirmed != true) return;

    final int qty = int.tryParse(qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      if (kDebugMode) debugPrint('[Return] invalid qty: $qty for saleItemId=${item.id}');
      return;
    }
    if (qty > maxQty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quantity cannot exceed $maxQty')));
      if (kDebugMode) debugPrint('[Return] qty exceeds max: $qty > $maxQty for saleItemId=${item.id}');
      return;
    }

    setState(() => _workingItemId = item.id);
    if (kDebugMode) {
      debugPrint('[Return] start saleId=${_sale.id} saleItemId=${item.id} qty=$qty reason="${reasonController.text}"');
    }

    try {
      final salesService = context.read<SalesService>();
      await salesService.createReturn(
        saleItemId: item.id!,
        quantityReturned: qty,
        reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
      );

      // Refresh sale + dependent data
      final fresh = await salesService.getSaleById(_sale.id);
      if (fresh != null) {
        _sale = fresh;
      }
      await _loadAuxiliaryData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return recorded')));
        // Refresh list totals/badges
        context.read<SalesBloc>().add(LoadSales());
      }
      if (kDebugMode) debugPrint('[Return] success saleId=${_sale.id} saleItemId=${item.id} qty=$qty');
    } catch (e, st) {
      // High-signal error log with context
      if (kDebugMode) {
        debugPrint('[Return][error] saleId=${_sale.id} saleItemId=${item.id} qty=$qty err=$e');
        debugPrintStack(stackTrace: st);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Return failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _workingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mobile-first, responsive bottom sheet using DraggableScrollableSheet
    final media = MediaQuery.of(context);
    final shortest = media.size.shortestSide;
    final isTablet = shortest >= 600;
    final initialChildSize = isTablet ? 0.75 : 0.92;
    final maxChildSize = isTablet ? 0.9 : 0.98;
    final minChildSize = isTablet ? 0.6 : 0.6;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (ctx, scrollController) {
        final theme = Theme.of(ctx);
        final hasAnyReturns = _sumReturnedAll() > 0;

        // Compact spacing for very small devices
        final compact = media.size.width < 360;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(
            top: 8,
            left: compact ? 6 : 8,
            right: compact ? 6 : 8,
            bottom: media.viewPadding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: SafeArea(
            top: false,
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(_error, style: TextStyle(color: AppColors.kError)),
                        ),
                      )
                    : CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                // Grab handle
                                Container(
                                  width: 42,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),

                          // Header
                          SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(compact ? 12 : AppSizes.padding),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimary.withOpacity(0.05),
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Sale #${_sale.id}",
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: compact ? 18 : null,
                                          ),
                                        ),
                                      ),
                                      _ChipBadge(
                                        text: 'Items ${_sale.items.length}',
                                        foreground: theme.colorScheme.primary,
                                        background: theme.colorScheme.primary.withOpacity(0.10),
                                      ),
                                      const SizedBox(width: 8),
                                      if (hasAnyReturns)
                                        _ChipBadge(
                                          text: 'Returned ${_sumReturnedAll()}',
                                          foreground: Colors.orange,
                                          background: Colors.orange.withOpacity(0.12),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Date/time
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(timeAgo(_sale.soldAt), style: theme.textTheme.bodyMedium),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Customer
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Customer: $_customerName",
                                          style: theme.textTheme.bodyMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Total
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, size: 17, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Total: \$${(_sale.totalAmount ?? 0).toStringAsFixed(2)}",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: compact ? 14 : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Payment status
                                  if (_invoice != null) _PaymentStatusRow(invoice: _invoice!),
                                ],
                              ),
                            ),
                          ),

                          // Items title
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : AppSizes.padding,
                              vertical: compact ? 8 : AppSizes.padding,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Items",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: compact ? 16 : null,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Items list
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : AppSizes.padding,
                              vertical: 4,
                            ),
                            sliver: SliverList.separated(
                              itemCount: _sale.items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = _sale.items[index];
                                final name = _productNames[item.productId] ?? 'Product #${item.productId}';
                                final double qty = item.quantitySold;
                                final String qtyStr =
                                    qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
                                final bool isBusy = _workingItemId == item.id;
                                final int returned = (item.id != null) ? (_returnedByItem[item.id!] ?? 0) : 0;

                                final narrow = media.size.width < 380;

                                // Mobile-first compact card with graceful wrap on narrow screens
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 10 : 12,
                                    vertical: compact ? 8 : 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        narrow ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                                    children: [
                                      // Row 1: Name + returned chip (wrap)
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: compact ? 13.5 : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (returned > 0) ...[
                                            const SizedBox(width: 6),
                                            _ChipBadge(
                                              text: 'Returned $returned',
                                              foreground: Colors.orange,
                                              background: Colors.orange.withOpacity(0.12),
                                            ),
                                          ],
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // Row 2: qty, unit price, line total (wrap to two rows on very narrow screens)
                                      if (!narrow)
                                        Row(
                                          children: [
                                            Expanded(child: Text('x$qtyStr', textAlign: TextAlign.left)),
                                            Expanded(
                                              child: Text(
                                                '@ \$${item.salePricePerQuantity.toStringAsFixed(2)}',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '\$${item.totalSalePrice.toStringAsFixed(2)}',
                                                textAlign: TextAlign.right,
                                                style: theme.textTheme.bodyMedium
                                                    ?.copyWith(fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('x$qtyStr'),
                                            const SizedBox(height: 2),
                                            Text('@ \$${item.salePricePerQuantity.toStringAsFixed(2)}'),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${item.totalSalePrice.toStringAsFixed(2)}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 8),

                                      // Row 3: Return button (full width on mobile)
                                      SizedBox(
                                        width: double.infinity,
                                        child: isBusy
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : OutlinedButton.icon(
                                                onPressed: (item.id == null || qty <= 0)
                                                    ? null
                                                    : () => _promptReturn(item),
                                                icon: const Icon(Icons.undo, size: 16),
                                                label: const Text('Return'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.kPrimary,
                                                  side: BorderSide(
                                                    color: AppColors.kPrimary.withOpacity(0.5),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: compact ? 10 : 12,
                                                    vertical: compact ? 10 : 12,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // bottom spacer
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ],
                      ),
          ),
        );
      },
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  final InvoiceStatus invoice;
  const _PaymentStatusRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final status = _interpret(invoice);
    return Row(
      children: [
        Icon(status.icon, size: 19, color: status.color),
        const SizedBox(width: 8),
        Chip(
          label: Text(
            status.text,
            style: TextStyle(color: status.color, fontWeight: FontWeight.bold),
          ),
          backgroundColor: status.color.withOpacity(0.10),
          side: BorderSide(color: status.color.withOpacity(0.15)),
        ),
        if (!invoice.isPaid && invoice.dueAmount > 0) ...[
          const SizedBox(width: 12),
          Text("Paid: \$${invoice.paidAmount.toStringAsFixed(2)}"),
          const SizedBox(width: 8),
          Text("Due: \$${invoice.dueAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.orange)),
        ],
      ],
    );
  }

  _PaymentStatus _interpret(InvoiceStatus inv) {
    final s = inv.status.toLowerCase();
    if (s == 'full' || inv.isPaid || (inv.dueAmount == 0 && inv.paidAmount >= inv.totalAmount)) {
      return const _PaymentStatus('Paid in Full', Colors.green, Icons.check_circle);
    }
    if (s == 'credited' || (inv.paidAmount > 0 && inv.dueAmount > 0)) {
      return const _PaymentStatus('Credit', Colors.orange, Icons.credit_card);
    }
    return const _PaymentStatus('Unpaid', Colors.red, Icons.highlight_off);
  }
}

class _PaymentStatus {
  final String text;
  final Color color;
  final IconData icon;
  const _PaymentStatus(this.text, this.color, this.icon);
}

class _ChipBadge extends StatelessWidget {
  final String text;
  final Color foreground;
  final Color background;

  const _ChipBadge({
    required this.text,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}