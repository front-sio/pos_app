import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/customers/bloc/customer_bloc.dart';
import 'package:sales_app/features/customers/bloc/customer_event.dart';
import 'package:sales_app/features/customers/services/customer_services.dart';


class CustomersModule {
  static RepositoryProvider<CustomerService> repositoryProvider() =>
      RepositoryProvider<CustomerService>(
        create: (_) => CustomerService(baseUrl: AppConfig.baseUrl),
      );

  static BlocProvider<CustomerBloc> blocProvider() => BlocProvider<CustomerBloc>(
        create: (ctx) => CustomerBloc(
          service: RepositoryProvider.of<CustomerService>(ctx),
        )..add(FetchCustomersPage(1, 20)),
      );
}