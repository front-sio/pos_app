import 'package:get_it/get_it.dart';
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/auth/data/auth_api_service.dart';
import 'package:sales_app/features/auth/data/auth_repository.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Register API Service and Repository
  locator.registerLazySingleton(() => AuthApiService(baseUrl: AppConfig.baseUrl));
  locator.registerLazySingleton(() => AuthRepository(locator<AuthApiService>()));
}
