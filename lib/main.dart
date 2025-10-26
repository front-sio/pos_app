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

// Notifications (Socket.IO realtime)
import 'package:sales_app/features/notitications/bloc/notification_bloc.dart';
import 'package:sales_app/features/notitications/bloc/notification_event.dart';
import 'package:sales_app/features/notitications/services/notification_socket_services.dart';

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

// Purchases
import 'package:sales_app/features/purchases/services/purchase_service.dart';
import 'package:sales_app/features/purchases/bloc/purchase_bloc.dart';

// Dashboard
import 'package:sales_app/features/dashboard/services/dashboard_service.dart';
import 'package:sales_app/features/dashboard/bloc/dashboard_bloc.dart';

// Settings (Currency)
import 'package:sales_app/features/settings/services/settings_service.dart';
import 'package:sales_app/features/settings/bloc/settings_bloc.dart';
import 'package:sales_app/features/settings/bloc/settings_event.dart';

// Expenses (NEW)
import 'package:sales_app/features/expenses/services/expense_services.dart';
import 'package:sales_app/features/expenses/bloc/expense_bloc.dart';
import 'package:sales_app/features/expenses/bloc/expense_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final baseUrl = AppConfig.baseUrl;
  final httpClient = AuthHttpClient();

  // Auth
  final authApiService = AuthApiService(baseUrl: baseUrl);
  final authRepository = AuthRepository(authApiService);

  // Services
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
  final purchaseService = PurchaseService();
  final dashboardService = DashboardService(purchaseService: purchaseService, salesService: salesService);
  final notificationSocketService = NotificationSocketService(); // Socket.IO realtime notifications
  final settingsService = SettingsService(baseUrl: baseUrl, client: httpClient);
  final expenseService = ExpenseService(baseUrl: baseUrl, client: httpClient);

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
        RepositoryProvider<PurchaseService>(create: (_) => purchaseService),
        RepositoryProvider<DashboardService>(create: (_) => dashboardService),
        RepositoryProvider<SettingsService>(create: (_) => settingsService),
        RepositoryProvider<ExpenseService>(create: (_) => expenseService),
        // Realtime notifications service (Socket.IO)
        RepositoryProvider<NotificationSocketService>(create: (_) => notificationSocketService),
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
          BlocProvider<PurchaseBloc>(create: (context) => PurchaseBloc(service: context.read<PurchaseService>())),
          BlocProvider<DashboardBloc>(create: (context) => DashboardBloc(service: context.read<DashboardService>())),
          BlocProvider<SettingsBloc>(create: (context) => SettingsBloc(context.read<SettingsService>())),
          BlocProvider<ExpenseBloc>(create: (context) => ExpenseBloc(service: context.read<ExpenseService>())),
          // Realtime Notifications BLoC (uses Socket.IO service)
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(service: context.read<NotificationSocketService>())
              ..add(const StartNotifications()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, next) => next is AuthAuthenticated || next is AuthUnauthenticated,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Kick off initial data loads after successful auth
              context.read<ProductsBloc>().add(FetchProducts());
              context.read<StockBloc>().add(const LoadProducts(page: 1));
              context.read<CustomerBloc>().add(FetchCustomersPage(1, 20));
              context.read<SupplierBloc>().add(FetchSuppliersPage(1, 20));
              context.read<InvoiceBloc>().add(const LoadInvoices());
              context.read<ProfitBloc>().add(LoadProfit(period: 'This Month', view: 'Daily'));
              context.read<ReportsBloc>().add(LoadDailyReport(DateTime.now()));
              context.read<UsersBloc>().add(LoadUsers());
              context.read<SettingsBloc>().add(const LoadSettings());
              context.read<SettingsBloc>().add(const LoadCurrencies());
              context.read<ExpenseBloc>().add(const LoadExpenses());

              // Optionally restart notifications with an auth token if available
              // context.read<NotificationBloc>().add(StartNotifications(token: state.token));
            }
            if (state is AuthUnauthenticated) {
              // Stop realtime notifications on logout
              context.read<NotificationBloc>().add(const StopNotifications());
            }
          },
          child: const PosBusinessApp(),
        ),
      ),
    ),
  );
}