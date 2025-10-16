import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/app.dart';
import 'package:sales_app/config/config.dart';

// Auth
import 'package:sales_app/features/auth/data/auth_api_service.dart';
import 'package:sales_app/features/auth/data/auth_repository.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';

// Customers
import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/features/customers/bloc/customer_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';

// Invoices
import 'package:sales_app/features/invoices/bloc/invoice_bloc.dart';
import 'package:sales_app/features/invoices/services/invoice_services.dart';

// Products
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_event.dart';
import 'package:sales_app/features/products/services/product_service.dart';

// Purchases
import 'package:sales_app/features/purchases/bloc/purchase_bloc.dart';
import 'package:sales_app/features/purchases/services/purchase_service.dart';

// Sales
import 'package:sales_app/features/sales/bloc/sales_bloc.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';
import 'package:sales_app/features/sales/repository/sales_repository.dart';

// Stocks
import 'package:sales_app/features/stocks/bloc/stock_bloc.dart';
import 'package:sales_app/features/stocks/bloc/stock_event.dart';
import 'package:sales_app/features/stocks/services/stock_service.dart';

// Profits
import 'package:sales_app/features/profits/bloc/profit_bloc.dart';
import 'package:sales_app/features/profits/bloc/profit_event.dart';
import 'package:sales_app/features/profits/services/profit_services.dart';

// Suppliers
import 'package:sales_app/features/suppliers/bloc/supplier_bloc.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_event.dart';
import 'package:sales_app/features/suppliers/services/supplier_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final baseUrl = AppConfig.baseUrl;

  // Services/Repositories
  final authApiService = AuthApiService(baseUrl: baseUrl);
  final authRepository = AuthRepository(authApiService);

  final productService = ProductService(baseUrl: baseUrl);
  final stockService = StockService(baseUrl: baseUrl);

  final salesService = SalesService(); // uses AppConfig.baseUrl internally
  final profitService = ProfitService();

  final customerService = CustomerService(baseUrl: baseUrl);
  final supplierService = SupplierService(baseUrl: baseUrl);

  final invoiceService = InvoiceService(baseUrl: baseUrl); // NEW

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepository),
        RepositoryProvider<ProductService>(create: (_) => productService),
        RepositoryProvider<StockService>(create: (_) => stockService),
        RepositoryProvider<SalesService>(create: (_) => salesService),
        RepositoryProvider<ProfitService>(create: (_) => profitService),
        RepositoryProvider<CustomerService>(create: (_) => customerService),
        RepositoryProvider<SupplierService>(create: (_) => supplierService),
        RepositoryProvider<InvoiceService>(create: (_) => invoiceService), // NEW

        // Provide SalesRepository so blocs can read it
        RepositoryProvider<SalesRepository>(
          create: (ctx) => SalesRepository(service: ctx.read<SalesService>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Auth
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(repository: authRepository)..add(AppStarted()),
          ),

          // Stock (inventory listing/pagination)
          BlocProvider<StockBloc>(
            create: (context) => StockBloc(
              productService: context.read<ProductService>(),
              stockService: context.read<StockService>(),
            )..add(const LoadProducts(page: 1)),
          ),

          // Products (catalog)
          BlocProvider<ProductsBloc>(
            create: (context) => ProductsBloc(
              productService: context.read<ProductService>(),
            )..add(FetchProducts()),
          ),

          // Sales
          BlocProvider<SalesBloc>(
            create: (context) => SalesBloc(
              repository: context.read<SalesRepository>(),
              productsBloc: context.read<ProductsBloc>(),
            ),
          ),

          // Purchases
          BlocProvider<PurchaseBloc>(
            create: (_) => PurchaseBloc(service: PurchaseService()),
          ),

          // Profits
          BlocProvider<ProfitBloc>(
            create: (context) =>
                ProfitBloc(service: context.read<ProfitService>())
                  ..add(LoadProfit(period: 'This Month', view: 'Daily')),
          ),

          // Customers
          BlocProvider<CustomerBloc>(
            create: (context) =>
                CustomerBloc(service: context.read<CustomerService>())
                  ..add(FetchCustomersPage(1, 20)),
          ),

          // Suppliers
          BlocProvider<SupplierBloc>(
            create: (context) =>
                SupplierBloc(service: context.read<SupplierService>())
                  ..add(FetchSuppliersPage(1, 20)),
          ),

          // Invoices (FIX: pass real service)
          BlocProvider<InvoiceBloc>(
            create: (context) => InvoiceBloc(service: context.read<InvoiceService>()),
          ),
        ],
        child: const PosBusinessApp(),
      ),
    ),
  );
}