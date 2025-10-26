import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';

// Services and blocs
import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/sales/bloc/sales_bloc.dart';
import 'package:sales_app/features/sales/bloc/sales_event.dart';
import 'package:sales_app/features/sales/bloc/sales_state.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';
import 'package:sales_app/features/sales/services/realtime_sales.dart';
import 'package:sales_app/features/invoices/services/realtime_invoices.dart';
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
  const SalesScreen({super.key, this.onAddNewSale});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with WidgetsBindingObserver {
  // Caches
  final Map<int, String> _customerNames = {}; // saleId -> customer name
  final Map<int, InvoiceStatus?> _invoiceBySale = {}; // saleId -> invoice
  final Map<int, int> _returnedQtyBySale = {}; // saleId -> sum returned qty
  final Map<int, Future<_TileData>> _tileFutures = {}; // cache futures per tile

  // Realtime
  final RealtimeSales _rtSales = RealtimeSales(debounce: const Duration(milliseconds: 500));
  final RealtimeInvoices _rtInvoices = RealtimeInvoices(debounce: const Duration(milliseconds: 500));
  StreamSubscription<String>? _rtSalesSub;
  StreamSubscription<String>? _rtInvSub;

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

    _rtSales.connect();
    _rtSalesSub = _rtSales.events.listen((type) {
      _scheduleThrottledRefresh();
    });

    _rtInvoices.connect();
    _rtInvSub = _rtInvoices.events.listen((type) {
      // invoice changes should reflect on Sales status/due quickly
      _scheduleThrottledRefresh();
    });

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

    _rtSalesSub?.cancel();
    _rtInvSub?.cancel();
    _rtSalesSub = null;
    _rtInvSub = null;

    _rtSales.dispose();
    _rtInvoices.dispose();
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

    // Items quantity sum (prefer existing list; if empty, fetch full sale)
    double itemsQty = _sumItemsQtyLocal(sale.items);
    if (itemsQty == 0.0) {
      try {
        final full = await salesService.getSaleById(sale.id);
        if (full != null) {
          itemsQty = _sumItemsQtyLocal(full.items);
        }
      } catch (_) {
        // ignore and keep 0.0
      }
    }

    return _TileData(
      customerName: customerName,
      invoice: invoice,
      returnedQty: returnedQty,
      itemsQty: itemsQty,
    );
  }

  double _sumItemsQtyLocal(List<SaleItem> items) {
    if (items.isEmpty) return 0.0;
    double sum = 0.0;
    for (final it in items) {
      sum += (it.quantitySold);
    }
    return sum;
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

  Widget _buildSummary(List<Sale> sales) {
    double totalItemsQty = 0;
    int totalReturned = 0;
    int paid = 0, credited = 0, unpaid = 0;

    for (final s in sales) {
      totalItemsQty += _sumItemsQtyLocal(s.items);
      final rid = _returnedQtyBySale[s.id];
      if (rid != null) totalReturned += rid;

      final inv = _invoiceBySale[s.id];
      if (inv != null) {
        final sLower = inv.status.toLowerCase();
        final isPaid = sLower == 'full' || inv.isPaid || (inv.dueAmount == 0 && inv.paidAmount >= inv.totalAmount);
        final isCredited = sLower == 'credited' || (inv.paidAmount > 0 && inv.dueAmount > 0);
        if (isPaid) {
          paid++;
        } else if (isCredited) {
          credited++;
        } else {
          unpaid++;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: _StatWrap(children: [
        _StatChip(label: 'Sales', value: '${sales.length}', color: Colors.indigo),
        _StatChip(label: 'Items', value: totalItemsQty.toStringAsFixed(2), color: Colors.teal),
        _StatChip(label: 'Returned', value: '$totalReturned', color: Colors.orange),
        _StatChip(label: 'Paid', value: '$paid', color: Colors.green),
        _StatChip(label: 'Credited', value: '$credited', color: Colors.amber.shade700),
        _StatChip(label: 'Unpaid', value: '$unpaid', color: Colors.red),
      ]),
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
            List<Sale> sales;
            if (state is SalesLoaded) {
              sales = [...state.sales];
            } else if (state is SalesLoading && _latestSales.isNotEmpty) {
              sales = [..._latestSales];
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
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: sales.length + 1,
                separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _buildSummary(sales);
                  }

                  final sale = sales[i - 1];
                  final isNew = DateTime.now().difference(sale.soldAt).abs() <= kNewSaleWindow;

                  final future = _tileFutures.putIfAbsent(sale.id, () => _loadTileData(sale));

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FutureBuilder<_TileData>(
                      future: future,
                      builder: (context, snap) {
                        final data = snap.data;
                        final invoice = data?.invoice;
                        final returnedQty = data?.returnedQty ?? (_returnedQtyBySale[sale.id] ?? 0);
                        final customerName = data?.customerName ?? (sale.customerId?.toString() ?? 'Unknown');
                        final itemsQty = data?.itemsQty ?? _sumItemsQtyLocal(sale.items);

                        final statusChip = invoice != null ? _statusChip(invoice) : const SizedBox.shrink();

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
                            boxShadow: [
                              if (theme.brightness == Brightness.light)
                                const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
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
                                              statusChip,
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
                                                  Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade600),
                                                  const SizedBox(width: 6),
                                                  Text('Items: ${itemsQty.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
                                                ],
                                              ),
                                              const Text('•'),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.undo, size: 16, color: Colors.grey.shade600),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Returned: $returnedQty',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: returnedQty > 0 ? Colors.orange.shade700 : Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  CurrencyFmt.format(context, sale.totalAmount ?? 0),
                                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                              if (invoice != null) ...[
                                                const SizedBox(width: 8),
                                                _InvoiceShortStatus(invoice: invoice),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              timeAgo(sale.soldAt),
                                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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

/* ----------------------------- Status helpers ------------------------------ */

class _InvoiceShortStatus extends StatelessWidget {
  final InvoiceStatus invoice;
  const _InvoiceShortStatus({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final s = invoice.status.toLowerCase();
    Color fg;
    String text;
    if (s == 'full' || invoice.isPaid || (invoice.dueAmount == 0 && invoice.paidAmount >= invoice.totalAmount)) {
      fg = Colors.green.shade700;
      text = 'Paid';
    } else if (s == 'credited' || (invoice.paidAmount > 0 && invoice.dueAmount > 0)) {
      fg = Colors.orange.shade700;
      text = 'Credited';
    } else {
      fg = Colors.red.shade700;
      text = 'Unpaid';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          text == 'Paid'
              ? Icons.check_circle
              : text == 'Credited'
                  ? Icons.credit_card
                  : Icons.highlight_off,
          size: 16,
          color: fg,
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TileData {
  final String customerName;
  final InvoiceStatus? invoice;
  final int returnedQty;
  final double itemsQty;

  _TileData({
    required this.customerName,
    required this.invoice,
    required this.returnedQty,
    required this.itemsQty,
  });
}

/* ------------------------------ Details bottom sheet ------------------------------ */

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

  double _safeUnitPrice(SaleItem item) {
    if (item.salePricePerQuantity != 0) return item.salePricePerQuantity;
    final q = item.quantitySold;
    if (q > 0) return _safeLineTotal(item, allowRecurse: false) / q;
    return 0.0;
  }

  double _safeLineTotal(SaleItem item, {bool allowRecurse = true}) {
    if (item.totalSalePrice != 0) return item.totalSalePrice;
    if (allowRecurse) return _safeUnitPrice(item) * item.quantitySold;
    return 0.0;
  }

  int _sumReturnedAll() => _returnedByItem.values.fold(0, (s, v) => s + v);

  Future<void> _promptReturn(SaleItem item) async {
    if (item.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot return: missing sale item id')));
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
    if (!mounted) return;

    final int qty = int.tryParse(qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    if (qty > maxQty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quantity cannot exceed $maxQty')));
      return;
    }

    setState(() => _workingItemId = item.id);

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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return recorded')));
      context.read<SalesBloc>().add(LoadSales());
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Return][error] saleId=${_sale.id} saleItemId=${item.id} err=$e');
        debugPrintStack(stackTrace: st);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Return failed: $e')));
    } finally {
      if (mounted) setState(() => _workingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Material(
          color: theme.cardColor,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : (_error.isNotEmpty
                          ? _ErrorRetry(message: _error, onRetry: _loadAuxiliaryData)
                          : _buildSheetBody()),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurfaceVariant,
                          side: BorderSide(color: cs.outline),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetBody() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final created = DateFormat.yMMMd().add_jm().format(_sale.soldAt);

    final totalItemsQty = _sale.items.fold<double>(0.0, (sum, it) => sum + it.quantitySold);
    final totalReturned = _sumReturnedAll();

    final kpis = <_Kpi>[
      _Kpi(label: 'Items', value: totalItemsQty.toStringAsFixed(2), icon: Icons.list_alt),
      _Kpi(label: 'Returned', value: '$totalReturned', icon: Icons.undo),
      _Kpi(label: 'Total', value: CurrencyFmt.format(context, _sale.totalAmount ?? 0), icon: Icons.attach_money),
      _Kpi(label: 'Sold At', value: created, icon: Icons.event),
    ];

    final chips = <Widget>[
      _TagChip(label: 'Sale #${_sale.id}'),
      if (_customerName.isNotEmpty && _customerName != 'Unknown') _TagChip(label: _customerName),
      if (_invoice != null) _TagChip(label: _invoice!.status.toUpperCase()),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCard(
            title: 'Sale #${_sale.id}',
            subtitle: 'Customer: $_customerName • ${timeAgo(_sale.soldAt)}',
            icon: Icons.receipt_long,
            color: cs.primary,
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
          const SizedBox(height: AppSizes.largePadding),
          if (_invoice != null) _PaymentStatusRow(invoice: _invoice!),
          if (_invoice != null) const SizedBox(height: AppSizes.largePadding),
          _KpiGrid(items: kpis),
          const SizedBox(height: AppSizes.largePadding),
          Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._sale.items.map((item) {
            final unitPrice = _safeUnitPrice(item);
            final lineTotal = _safeLineTotal(item);
            final returnedQty = _returnedByItem[item.id ?? -1] ?? 0;

            return _ItemTile(
              title: _productNames[item.productId] ?? 'Product #${item.productId}',
              quantity: item.quantitySold,
              unitPrice: unitPrice,
              total: lineTotal,
              onReturn: () => _promptReturn(item),
              returning: _workingItemId == item.id,
              returnedQty: returnedQty,
            );
          }),
          const SizedBox(height: AppSizes.padding),
          Divider(color: cs.outlineVariant),
          const SizedBox(height: AppSizes.padding),
          Row(
            children: [
              Expanded(
                child: Text('Total Amount', style: theme.textTheme.titleMedium),
              ),
              Text(
                CurrencyFmt.format(context, _sale.totalAmount ?? 0),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- UI widgets ------------------------------ */

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
          Text("Paid: ${CurrencyFmt.format(context, invoice.paidAmount)}"),
          const SizedBox(width: 8),
          Text(
            "Due: ${CurrencyFmt.format(context, invoice.dueAmount)}",
            style: const TextStyle(color: Colors.orange),
          ),
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

class _HeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _HeaderCard({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: cs.primary),
      side: BorderSide(color: cs.primary.withOpacity(0.4)),
      backgroundColor: cs.primary.withOpacity(0.08),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;

  _Kpi({required this.label, required this.value, required this.icon});
}

class _KpiGrid extends StatelessWidget {
  final List<_Kpi> items;
  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w < 420 ? 1 : (w < 680 ? 2 : 4);
      final itemWidth = (w - (cols - 1) * 12) / cols;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items
            .map((e) => SizedBox(
                  width: itemWidth,
                  child: _KpiCard(kpi: e),
                ))
            .toList(),
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(kpi.icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kpi.label, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(kpi.value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String title;
  final double quantity;
  final double unitPrice;
  final double total;
  final int returnedQty;
  final VoidCallback onReturn;
  final bool returning;

  const _ItemTile({
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.returnedQty,
    required this.onReturn,
    required this.returning,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${quantity.toStringAsFixed(2)} × ${CurrencyFmt.format(context, unitPrice)} = ${CurrencyFmt.format(context, total)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Returned: $returnedQty',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: returnedQty > 0 ? Colors.orange.shade700 : Colors.grey.shade700,
                    ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          returning
              ? const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Return'),
                ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 36),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _StatWrap extends StatelessWidget {
  final List<Widget> children;
  const _StatWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final runSpacing = 10.0;
      final spacing = 10.0;
      final cols = w < 420 ? 2 : (w < 680 ? 3 : 6);
      final itemWidth = (w - (cols - 1) * spacing) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: children.map((e) => SizedBox(width: itemWidth, child: e)).toList(),
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.circle, size: 12, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }
}