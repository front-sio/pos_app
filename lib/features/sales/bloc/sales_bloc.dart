import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_state.dart';
import 'package:sales_app/features/products/data/product_model.dart';
import 'package:sales_app/features/sales/bloc/sales_event.dart';
import 'package:sales_app/features/sales/bloc/sales_state.dart';
import 'package:sales_app/features/sales/data/new_sale_dto.dart';
import 'package:sales_app/features/sales/data/sale_item.dart';
import 'package:sales_app/features/sales/repository/sales_repository.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SalesRepository _repository;
  final ProductsBloc productsBloc;
  final Map<Product, int> _cart = {};

  SalesBloc({
    required SalesRepository repository,
    required this.productsBloc,
  }) : _repository = repository,
       super(SalesInitial()) {
    on<LoadSales>(_onLoadSales);
    on<AddSale>(_onAddSale);
    on<AddItemToCart>(_onAddItemToCart);
    on<RemoveItemFromCart>(_onRemoveItemFromCart);
    on<UpdateItemQuantity>(_onUpdateItemQuantity);
    on<ResetCart>(_onResetCart);
    on<AddItemFromBarcode>(_onAddItemFromBarcode);
  }

  void _onAddItemToCart(AddItemToCart event, Emitter<SalesState> emit) {
    if (_cart.containsKey(event.product)) {
      _cart[event.product] = _cart[event.product]! + 1;
    } else {
      _cart[event.product] = 1;
    }
    emit(CartUpdated(Map.from(_cart)));
  }

  void _onRemoveItemFromCart(RemoveItemFromCart event, Emitter<SalesState> emit) {
    if (_cart.containsKey(event.product)) {
      if (_cart[event.product]! > 1) {
        _cart[event.product] = _cart[event.product]! - 1;
      } else {
        _cart.remove(event.product);
      }
    }
    emit(CartUpdated(Map.from(_cart)));
  }

  void _onUpdateItemQuantity(UpdateItemQuantity event, Emitter<SalesState> emit) {
    if (event.quantity > 0) {
      _cart[event.product] = event.quantity;
    } else {
      _cart.remove(event.product);
    }
    emit(CartUpdated(Map.from(_cart)));
  }

  void _onResetCart(ResetCart event, Emitter<SalesState> emit) {
    _cart.clear();
    emit(CartUpdated(Map.from(_cart)));
  }

  void _onAddItemFromBarcode(AddItemFromBarcode event, Emitter<SalesState> emit) {
    try {
      final input = event.barcode.trim();
      if (input.isEmpty) {
        emit(const SalesError('Please scan or enter a barcode.'));
        return;
      }
      final product = findProductByBarcode(input);
      if (product != null) {
        add(AddItemToCart(product));
      } else {
        emit(SalesError('Product with barcode $input not found.'));
      }
    } catch (e) {
      emit(SalesError(e.toString()));
    }
  }

  Future<void> _onLoadSales(LoadSales event, Emitter<SalesState> emit) async {
    try {
      emit(SalesLoading());
      final sales = await _repository.getAllSales();
      emit(SalesLoaded(sales));
    } catch (e) {
      emit(SalesError(e.toString()));
    }
  }

  Future<void> _onAddSale(AddSale event, Emitter<SalesState> emit) async {
    try {
      if (event.customerId <= 0) {
        emit(const SalesError('Select a valid customer before checkout.'));
        return;
      }

      final overridesById = {for (var o in event.overrides) o.productId: o};

      final items = _cart.entries.map((entry) {
        final product = entry.key;
        final qty = entry.value;
        final defaultUnitPrice = product.price ?? 0.0;
        final override = overridesById[product.id];
        final unitPrice = override?.unitPrice ?? defaultUnitPrice;
        final quantity = qty.toDouble();
        final total = unitPrice * quantity;
        return SaleItem(
          productId: product.id,
          quantitySold: quantity,
          salePricePerQuantity: unitPrice,
          totalSalePrice: total,
        );
      }).toList();

      if (items.isEmpty) {
        emit(const SalesError('Cart is empty.'));
        return;
      }

      final newSaleDto = NewSaleDto(
        customerId: event.customerId,
        items: items,
        paidAmount: event.paidAmount,
        orderDiscountAmount: event.orderDiscountAmount,
      );

      await _repository.createSale(newSaleDto);

      _cart.clear();
      emit(CartUpdated(Map.from(_cart)));
      emit(const SalesOperationSuccess("Sale added successfully"));
      add(const LoadSales());
    } catch (e) {
      emit(SalesError(e.toString()));
      add(const LoadSales());
    }
  }

  Product? findProductByBarcode(String barcode) {
    if (productsBloc.state is ProductsLoaded) {
      final products = (productsBloc.state as ProductsLoaded).products;
      try {
        return products.firstWhere(
          (product) => (product.barcode ?? '').trim() == barcode
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}