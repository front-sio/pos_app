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
  const CreateInvoiceEvent({
    required this.customerId,
    required this.totalAmount,
    this.status = 'unpaid',
    this.saleIds = const [],
  });
  @override
  List<Object?> get props => [customerId, totalAmount, status, saleIds];
}

class AddPaymentEvent extends InvoiceEvent {
  final int invoiceId;
  final double amount;
  const AddPaymentEvent(this.invoiceId, this.amount);
  @override
  List<Object?> get props => [invoiceId, amount];
}