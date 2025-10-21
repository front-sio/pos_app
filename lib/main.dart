import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/app.dart';
import 'package:sales_app/config/config.dart';

// Auth
import 'package:sales_app/features/auth/data/auth_api_service.dart';
import 'package:sales_app/features/auth/data/auth_repository.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';

// Customers
import 'package:sales_app/features/customers/services/customer_services.dart';
import 'package:sales_app/features/customers/bloc/customer_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';

// Invoices
import 'package:sales_app/features/invoices/bloc/invoice_bloc.dart';
import 'package:sales_app/features/invoices/bloc/invoice_event.dart';
import 'package:sales_app/features/invoices/services/invoice_services.dart';

// Products
import 'package:sales_app/features/products/bloc/products_bloc.dart';
import 'package:sales_app/features/products/bloc/products_event.dart';
import 'package:sales_app/features/products/services/product_service.dart';

// Stocks
import 'package:sales_app/features/stocks/services/stock_service.dart';
import 'package:sales_app/features/stocks/bloc/stock_bloc.dart';
import 'package:sales_app/features/stocks/bloc/stock_event.dart';

// Sales
import 'package:sales_app/features/sales/bloc/sales_bloc.dart';
import 'package:sales_app/features/sales/repository/sales_repository.dart';
import 'package:sales_app/features/sales/services/sales_service.dart';

// Profits
import 'package:sales_app/features/profits/bloc/profit_bloc.dart';
import 'package:sales_app/features/profits/bloc/profit_event.dart';
import 'package:sales_app/features/profits/services/profit_services.dart';

// Suppliers
import 'package:sales_app/features/suppliers/services/supplier_service.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_bloc.dart';
import 'package:sales_app/features/suppliers/bloc/supplier_event.dart';

// Reports
import 'package:sales_app/features/reports/services/reports_service.dart';
import 'package:sales_app/features/reports/repository/reports_repository.dart';
import 'package:sales_app/features/reports/bloc/reports_bloc.dart';
import 'package:sales_app/features/reports/bloc/reports_event.dart';

// Users
import 'package:sales_app/features/users/services/users_api_service.dart';
import 'package:sales_app/features/users/repository/users_repository.dart';
import 'package:sales_app/features/users/presentation/bloc/users_bloc.dart';
import 'package:sales_app/features/users/presentation/bloc/users_event.dart';

// Profile
import 'package:sales_app/features/profile/presentation/bloc/profile_bloc.dart';

// HTTP wrapper
import 'package:sales_app/network/auth_http_client.dart';

// Purchases (ADDED)
import 'package:sales_app/features/purchases/services/purchase_service.dart';
import 'package:sales_app/features/purchases/bloc/purchase_bloc.dart';
import 'package:sales_app/features/purchases/bloc/purchase_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final baseUrl = AppConfig.baseUrl;

  final httpClient = AuthHttpClient();

  final authApiService = AuthApiService(baseUrl: baseUrl);
  final authRepository = AuthRepository(authApiService);

  final productService = ProductService(baseUrl: baseUrl);
  final stockService = StockService(baseUrl: baseUrl);

  final salesService = SalesService();
  final profitService = ProfitService();

  final customerService = CustomerService(baseUrl: baseUrl, client: httpClient);
  final supplierService = SupplierService(baseUrl: baseUrl);

  final invoiceService = InvoiceService(baseUrl: baseUrl, client: httpClient);

  final reportsService = ReportsService(baseUrl: baseUrl);
  final reportsRepository = ReportsRepository(service: reportsService);

  final usersApiService = UsersApiService(baseUrl: baseUrl);
  final usersRepository = UsersRepository(api: usersApiService, auth: authRepository);

  // ADDED: PurchaseService
  final purchaseService = PurchaseService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepository),
        RepositoryProvider<AuthHttpClient>(create: (_) => httpClient),
        RepositoryProvider<ProductService>(create: (_) => productService),
        RepositoryProvider<StockService>(create: (_) => stockService),
        RepositoryProvider<SalesService>(create: (_) => salesService),
        RepositoryProvider<ProfitService>(create: (_) => profitService),
        RepositoryProvider<CustomerService>(create: (_) => customerService),
        RepositoryProvider<SupplierService>(create: (_) => supplierService),
        RepositoryProvider<ReportsService>(create: (_) => reportsService),
        RepositoryProvider<ReportsRepository>(create: (_) => reportsRepository),
        RepositoryProvider<InvoiceService>(create: (_) => invoiceService),
        RepositoryProvider<UsersApiService>(create: (_) => usersApiService),
        RepositoryProvider<UsersRepository>(create: (_) => usersRepository),
        // ADDED
        RepositoryProvider<PurchaseService>(create: (_) => purchaseService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => AuthBloc(repository: authRepository)..add(AppStarted())),
          BlocProvider<StockBloc>(create: (context) => StockBloc(
                productService: context.read<ProductService>(),
                stockService: context.read<StockService>(),
              )),
          BlocProvider<ProductsBloc>(create: (context) => ProductsBloc(
                productService: context.read<ProductService>(),
              )),
          BlocProvider<SalesBloc>(create: (context) => SalesBloc(
                repository: SalesRepository(service: context.read<SalesService>()),
                productsBloc: context.read<ProductsBloc>(),
              )),
          BlocProvider<ProfitBloc>(create: (context) => ProfitBloc(service: context.read<ProfitService>())),
          BlocProvider<CustomerBloc>(create: (context) => CustomerBloc(service: context.read<CustomerService>())),
          BlocProvider<SupplierBloc>(create: (context) => SupplierBloc(service: context.read<SupplierService>())),
          BlocProvider<InvoiceBloc>(create: (context) => InvoiceBloc(service: context.read<InvoiceService>())),
          BlocProvider<ReportsBloc>(create: (context) => ReportsBloc(repository: context.read<ReportsRepository>())),
          BlocProvider<UsersBloc>(create: (context) => UsersBloc(repository: context.read<UsersRepository>())),
          BlocProvider<ProfileBloc>(create: (context) => ProfileBloc(repository: context.read<UsersRepository>())),
          // ADDED: PurchaseBloc
          BlocProvider<PurchaseBloc>(create: (context) => PurchaseBloc(service: context.read<PurchaseService>())..add(const LoadPurchases())),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, next) => next is AuthAuthenticated || next is AuthUnauthenticated,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.read<ProductsBloc>().add(FetchProducts());
              context.read<StockBloc>().add(const LoadProducts(page: 1));
              context.read<CustomerBloc>().add(FetchCustomersPage(1, 20));
              context.read<SupplierBloc>().add(FetchSuppliersPage(1, 20));
              context.read<InvoiceBloc>().add(const LoadInvoices());
              context.read<ProfitBloc>().add(LoadProfit(period: 'This Month', view: 'Daily'));
              context.read<ReportsBloc>().add(LoadDailyReport(DateTime.now()));
              context.read<UsersBloc>().add(LoadUsers());
              // Ensure purchases refresh after login
              context.read<PurchaseBloc>().add(const LoadPurchases());
            }
          },
          child: const PosBusinessApp(),
        ),
      ),
    ),
  );
}