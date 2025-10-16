import 'package:equatable/equatable.dart';
import 'package:sales_app/features/invoices/data/invoice_model.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoicesInitial extends InvoiceState {}
class InvoicesLoading extends InvoiceState {}

class InvoicesLoaded extends InvoiceState {
  final List<Invoice> invoices;
  const InvoicesLoaded(this.invoices);
  @override
  List<Object?> get props => [invoices];
}

class InvoiceDetailsLoaded extends InvoiceState {
  final Invoice invoice;
  final List<Payment> payments;
  const InvoiceDetailsLoaded(this.invoice, this.payments);
  @override
  List<Object?> get props => [invoice, payments];
}

class InvoicesError extends InvoiceState {
  final String message;
  const InvoicesError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoiceOperationSuccess extends InvoiceState {
  final String message;
  const InvoiceOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}