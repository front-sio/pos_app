import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/purchases/bloc/purchase_event.dart';
import 'package:sales_app/features/purchases/bloc/purchase_state.dart';
import 'package:sales_app/features/purchases/services/purchase_service.dart';
import 'package:sales_app/features/purchases/data/purchase_model.dart';
import 'package:sales_app/utils/api_error_handler.dart';

class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  final PurchaseService service;

  PurchaseBloc({required this.service}) : super(PurchaseInitial()) {
    on<LoadPurchases>(_onLoad);
    on<CreatePurchase>(_onCreate);
    on<UpdatePurchasePayment>(_onUpdatePayment);
  }

  Future<void> _onLoad(LoadPurchases event, Emitter<PurchaseState> emit) async {
    try {
      emit(PurchaseLoading());
      final list = await service.getAllPurchases();
      emit(PurchaseLoaded(list));
    } catch (e) {
      final errorMessage = e is ApiException 
          ? e.message 
          : ApiErrorHandler.getErrorMessage(e);
      emit(PurchaseError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onCreate(CreatePurchase event, Emitter<PurchaseState> emit) async {
    final hadLoaded = state is PurchaseLoaded;
    final prev = hadLoaded ? (state as PurchaseLoaded).purchases : const <Purchase>[];

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
      final errorMessage = e is ApiException 
          ? e.message 
          : ApiErrorHandler.getErrorMessage(e);
      emit(PurchaseError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
      if (hadLoaded) emit(PurchaseLoaded(prev));
    }
  }

  Future<void> _onUpdatePayment(UpdatePurchasePayment event, Emitter<PurchaseState> emit) async {
    final hadLoaded = state is PurchaseLoaded;
    final prev = hadLoaded ? (state as PurchaseLoaded).purchases : const <Purchase>[];
    try {
      await service.updatePurchasePayment(
        purchaseId: event.purchaseId,
        paidAmount: event.newPaidAmountAbsolute,
        status: event.statusOverride,
      );
      final list = await service.getAllPurchases();
      emit(const PurchaseOperationSuccess('Payment updated'));
      emit(PurchaseLoaded(list));
    } catch (e) {
      final errorMessage = e is ApiException 
          ? e.message 
          : ApiErrorHandler.getErrorMessage(e);
      emit(PurchaseError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
      if (hadLoaded) emit(PurchaseLoaded(prev));
    }
  }
}