import 'package:equatable/equatable.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoices extends InvoiceEvent {
  const LoadInvoices();
}

class LoadInvoiceDetails extends InvoiceEvent {
  final int invoiceId;
  const LoadInvoiceDetails(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class CreateInvoiceEvent extends InvoiceEvent {
  final int customerId;
  final double totalAmount;
  final String status; // paid|unpaid
  final List<int> saleIds;
  final double discountAmount;
  const CreateInvoiceEvent({
    required this.customerId,
    required this.totalAmount,
    this.status = 'unpaid',
    this.saleIds = const [],
    this.discountAmount = 0,
  });
  @override
  List<Object?> get props => [customerId, totalAmount, status, saleIds, discountAmount];
}

class AddPaymentEvent extends InvoiceEvent {
  final int invoiceId;
  final double amount;
  const AddPaymentEvent(this.invoiceId, this.amount);
  @override
  List<Object?> get props => [invoiceId, amount];
}

class ApplyDiscountToInvoice extends InvoiceEvent {
  final int invoiceId;
  final double discountAmount;
  const ApplyDiscountToInvoice({required this.invoiceId, required this.discountAmount});
  @override
  List<Object?> get props => [invoiceId, discountAmount];
}

class UpdateInvoiceTotalEvent extends InvoiceEvent {
  final int invoiceId;
  final double newTotalAmount;
  const UpdateInvoiceTotalEvent({required this.invoiceId, required this.newTotalAmount});
  @override
  List<Object?> get props => [invoiceId, newTotalAmount];
}