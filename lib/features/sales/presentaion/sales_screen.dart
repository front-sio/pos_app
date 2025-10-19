import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'package:sales_app/features/sales/services/realtime_sales.dart';
import 'package:sales_app/utils/interaction_lock.dart';

// Models
import 'package:sales_app/features/sales/data/sales_model.dart';
import 'package:sales_app/features/sales/data/sale_item.dart';

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

class SalesScreen extends StatefulWidget {
  final VoidCallback? onAddNewSale;
  const SalesScreen({Key? key, this.onAddNewSale}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with WidgetsBindingObserver {
  // Caches
  final Map<int, String> _customerNames = {}; // saleId -> name
  final Map<int, InvoiceStatus?> _invoiceBySale = {}; // saleId -> invoice
  final Map<int, int> _returnedQtyBySale = {}; // saleId -> sum returned qty
  final Map<int, Future<_TileData>> _tileFutures = {}; // cache futures to avoid flicker

  // Realtime via Socket.IO
  final RealtimeSales _rt = RealtimeSales(debounce: const Duration(milliseconds: 500));
  StreamSubscription<String>? _rtSub;

  // Refresh throttling
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _refreshDebounce;
  static const Duration kRefreshCooldown = Duration(milliseconds: 900);

  // Safety poll to self-heal if socket misses events (rare)
  Timer? _safetyPoller;
  static const Duration kSafetyPollEvery = Duration(seconds: 30);

  // Preserve last-known list to avoid spinner flicker
  List<Sale> _latestSales = const [];

  static const Duration kNewSaleWindow = Duration(minutes: 10);

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRealtime();
    } else if (state == AppLifecycleState.paused) {
      _stopRealtime();
    }
  }

  Future<void> _refresh() async {
    context.read<SalesBloc>().add(LoadSales());
    await Future.delayed(const Duration(milliseconds: 150));
  }

  void _scheduleThrottledRefresh() {
    if (InteractionLock.instance.isInteracting.value == true) {
      if (kDebugMode) debugPrint('[SalesScreen][RT] skip refresh - interacting');
      return;
    }
    final now = DateTime.now();
    final since = now.difference(_lastRefresh);
    if (since < kRefreshCooldown) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(kRefreshCooldown - since, () {
        _lastRefresh = DateTime.now();
        _tileFutures.clear(); // invalidate cached per-tile futures
        context.read<SalesBloc>().add(LoadSales());
      });
      return;
    }
    _lastRefresh = now;
    _tileFutures.clear();
    context.read<SalesBloc>().add(LoadSales());
  }

  void _startRealtime() {
    _stopRealtime();

    // Start Socket.IO and listen
    _rt.connect();
    _rtSub = _rt.events.listen((type) {
      if (kDebugMode) debugPrint('[SalesScreen][RT] event: $type');
      _scheduleThrottledRefresh();
    });

    // Safety poll (lightweight, infrequent)
    _safetyPoller = Timer.periodic(kSafetyPollEvery, (_) {
      if (InteractionLock.instance.isInteracting.value == true) return;
      _scheduleThrottledRefresh();
    });
  }

  void _stopRealtime() {
    _safetyPoller?.cancel();
    _safetyPoller = null;

    _refreshDebounce?.cancel();
    _refreshDebounce = null;

    _rtSub?.cancel();
    _rtSub = null;

    _rt.dispose();
  }

  Future<_TileData> _loadTileData(Sale sale) async {
    final salesService = context.read<SalesService>();
    final customerService = context.read<CustomerService>();

    // Customer name (cache by sale id)
    String customerName = _customerNames[sale.id] ?? (sale.customerId != null ? 'Customer #${sale.customerId}' : 'Unknown');

    if (!_customerNames.containsKey(sale.id) && sale.customerId != null && sale.customerId! > 0) {
      try {
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
      body: BlocListener<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SalesLoaded) {
            _latestSales = [...state.sales];
          }
        },
        child: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            // Prefer last known data to avoid spinner flicker
            List<Sale> sales;
            if (state is SalesLoaded) {
              sales = [...state.sales];
            } else if (state is SalesLoading && _latestSales.isNotEmpty) {
              sales = [..._latestSales]; // show previous data while loading
            } else if (state is SalesError) {
              return Center(child: Text(state.message, style: TextStyle(color: AppColors.kError)));
            } else {
              sales = const [];
            }

            if (sales.isEmpty) {
              if (state is SalesLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(child: Text("No sales yet", style: theme.textTheme.titleMedium));
            }

            sales.sort((a, b) => b.soldAt.compareTo(a.soldAt));

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

                  // Cache future to avoid restarting per rebuild
                  final future = _tileFutures.putIfAbsent(sale.id, () => _loadTileData(sale));

                  return FutureBuilder<_TileData>(
                    future: future,
                    builder: (context, snap) {
                      final data = snap.data;
                      final invoice = data?.invoice;
                      final returnedQty = data?.returnedQty ?? 0;
                      final customerName = data?.customerName ?? (sale.customerId?.toString() ?? 'Unknown');

                      return Material(
                        key: ValueKey('sale-${sale.id}'), // stable key to reduce flicker
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
      final fetched = await salesService.getSaleById(_sale.id);
      if (fetched != null) _sale = fetched;

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

      _invoice = _sale.invoiceStatus ?? await salesService.getInvoiceBySaleId(_sale.id);

      _returnedByItem.clear();
      final returns = await salesService.getReturnsBySaleId(_sale.id);
      for (final r in returns) {
        _returnedByItem[r.saleItemId] = (_returnedByItem[r.saleItemId] ?? 0) + r.quantityReturned;
      }
      if (kDebugMode) debugPrint('[SaleDetailsSheet] returns agg: $_returnedByItem');
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot return: missing sale item id')));
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

      final fresh = await salesService.getSaleById(_sale.id);
      if (fresh != null) _sale = fresh;
      await _loadAuxiliaryData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return recorded')));
        context.read<SalesBloc>().add(LoadSales());
      }
      if (kDebugMode) debugPrint('[Return] success saleId=${_sale.id} saleItemId=${item.id} qty=$qty');
    } catch (e, st) {
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
    // build implemented above
    return const SizedBox.shrink();
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
          label: Text(status.text, style: TextStyle(color: status.color, fontWeight: FontWeight.bold)),
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