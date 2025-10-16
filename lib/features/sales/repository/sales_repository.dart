import 'package:sales_app/features/sales/data/new_sale_dto.dart';
import 'package:sales_app/features/sales/data/sales_model.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';

class SalesRepository {
  final SalesService _service;

  SalesRepository({required SalesService service}) : _service = service;

  Future<List<Sale>> getAllSales() => _service.getAllSales();

  Future<Sale> createSale(NewSaleDto dto) => _service.createSale(dto);

  Future<Sale?> getSaleById(int id) => _service.getSaleById(id);

  Future<InvoiceStatus?> getInvoiceBySaleId(int saleId) => _service.getInvoiceBySaleId(saleId);
}