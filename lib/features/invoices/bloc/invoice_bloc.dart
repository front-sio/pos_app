import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/invoices/bloc/invoice_event.dart';
import 'package:sales_app/features/invoices/bloc/invoice_state.dart';
import 'package:sales_app/features/invoices/services/invoice_services.dart';
import 'package:sales_app/features/invoices/services/export_service.dart';
import 'package:sales_app/utils/api_error_handler.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceService service;

  InvoiceBloc({required this.service}) : super(InvoicesInitial()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<LoadInvoiceDetails>(_onLoadInvoiceDetails);
    on<CreateInvoiceEvent>(_onCreateInvoice);
    on<AddPaymentEvent>(_onAddPayment);
    on<ApplyDiscountToInvoice>(_onApplyDiscount);
    on<UpdateInvoiceTotalEvent>(_onUpdateInvoiceTotal);
  }

  Future<void> _onLoadInvoices(LoadInvoices event, Emitter<InvoiceState> emit) async {
    try {
      emit(InvoicesLoading());
      final list = await service.getInvoices();
      emit(InvoicesLoaded(list));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(InvoicesError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onLoadInvoiceDetails(LoadInvoiceDetails event, Emitter<InvoiceState> emit) async {
    try {
      emit(InvoiceDetailsLoading());
      final inv = await service.getInvoice(event.invoiceId);
      final pays = await service.getPayments(event.invoiceId);
      emit(InvoiceDetailsLoaded(inv, pays));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(InvoicesError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onCreateInvoice(CreateInvoiceEvent event, Emitter<InvoiceState> emit) async {
    try {
      // Generate PDF if customer email is provided
      String? pdfBase64;
      if (event.customerEmail != null && event.customerEmail!.isNotEmpty && event.salesData != null) {
        try {
          // Convert salesData to InvoiceSaleSection format
          final sections = <InvoiceSaleSection>[];
          for (var saleData in event.salesData!) {
            final lines = <InvoiceLineData>[];
            if (saleData['items'] != null) {
              for (var item in saleData['items']) {
                lines.add(InvoiceLineData(
                  product: item['product_name'] ?? 'Product',
                  soldQty: (item['quantity'] ?? 0).toDouble(),
                  returnedQty: 0,
                  unitPrice: (item['unit_price'] ?? 0).toDouble(),
                ));
              }
            }
            sections.add(InvoiceSaleSection(
              saleId: saleData['id'] ?? 0,
              soldAt: DateTime.tryParse(saleData['created_at'] ?? '') ?? DateTime.now(),
              lines: lines,
            ));
          }

          // Generate PDF bytes
          final pdfBytes = await ExportService.generateInvoicePdfBytes(
            invoiceId: 0, // Will be assigned by backend
            customerName: event.customerName ?? 'Customer',
            createdAt: DateTime.now(),
            statusText: event.status,
            sections: sections,
            amountPaid: event.status == 'paid' ? event.totalAmount : 0,
            amountDue: event.status == 'unpaid' ? event.totalAmount : 0,
            fmtCurrency: (amount) => '\$${amount.toStringAsFixed(2)}',
            customer: PartyInfo(
              name: event.customerName ?? 'Customer',
              email: event.customerEmail,
            ),
          );

          // Convert to base64
          pdfBase64 = base64Encode(pdfBytes);
        } catch (pdfError) {
          print('⚠️ Failed to generate PDF: $pdfError');
          // Continue without PDF
        }
      }

      // Create invoice with PDF attachment
      await service.createInvoice(
        customerId: event.customerId,
        totalAmount: event.totalAmount,
        status: event.status,
        saleIds: event.saleIds,
        discountAmount: event.discountAmount,
        pdfAttachment: pdfBase64,
      );
      emit(const InvoiceOperationSuccess('Invoice created and email sent'));
      add(const LoadInvoices());
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(InvoicesError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onAddPayment(AddPaymentEvent event, Emitter<InvoiceState> emit) async {
    try {
      await service.addPayment(invoiceId: event.invoiceId, amount: event.amount);
      emit(const InvoiceOperationSuccess('Payment added'));
      add(LoadInvoiceDetails(event.invoiceId));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(InvoicesError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onApplyDiscount(ApplyDiscountToInvoice event, Emitter<InvoiceState> emit) async {
    try {
      await service.applyDiscount(invoiceId: event.invoiceId, discountAmount: event.discountAmount);
      emit(const InvoiceOperationSuccess('Discount applied'));
      add(LoadInvoiceDetails(event.invoiceId));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(InvoicesError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }

  Future<void> _onUpdateInvoiceTotal(UpdateInvoiceTotalEvent event, Emitter<InvoiceState> emit) async {
    try {
      await service.updateInvoiceTotal(invoiceId: event.invoiceId, newTotalAmount: event.newTotalAmount);
      emit(const InvoiceOperationSuccess('Invoice updated'));
      add(LoadInvoiceDetails(event.invoiceId));
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : ApiErrorHandler.getErrorMessage(e);
      emit(InvoicesError(errorMessage, isNetworkError: e is ApiException && e.isNetworkError));
    }
  }
}