import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/purchases/bloc/purchase_event.dart';
import 'package:sales_app/features/purchases/bloc/purchase_state.dart';
import 'package:sales_app/features/purchases/services/purchase_service.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';

class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  final PurchaseService service;

  PurchaseBloc({required this.service}) : super(PurchaseInitial()) {
    on<LoadPurchases>(_onLoad);
    on<CreatePurchase>(_onCreate);
  }

  Future<void> _onLoad(LoadPurchases event, Emitter<PurchaseState> emit) async {
    try {
      emit(PurchaseLoading());
      final list = await service.getAllPurchases();
      emit(PurchaseLoaded(list));
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> _onCreate(CreatePurchase event, Emitter<PurchaseState> emit) async {
    // Keep current list visible while submitting (avoid flicker)
    final hadLoaded = state is PurchaseLoaded;
    final List<Purchase> previousList =
        hadLoaded ? (state as PurchaseLoaded).purchases : const <Purchase>[];

    try {
      await service.createPurchase(
        supplierId: event.supplierId,
        status: event.status,
        paidAmount: event.paidAmount,
        notes: event.notes,
        items: event.items,
      );

      final list = await service.getAllPurchases();

      emit(const PurchaseOperationSuccess('Purchase recorded successfully'));
      emit(PurchaseLoaded(list));
    } catch (e) {
      emit(PurchaseError(e.toString()));
      if (hadLoaded) {
        emit(PurchaseLoaded(previousList));
      }
    }
  }
}