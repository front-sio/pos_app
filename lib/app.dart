import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/features/auth/presentation/login_screen.dart';
import 'package:sales_app/features/auth/presentation/reset_password_screen.dart';
import 'package:sales_app/features/settings/presentation/currency_settings_screen.dart';
import 'package:sales_app/theme/app_theme.dart';
import 'package:sales_app/widgets/admin_scaffold.dart';
import 'package:sales_app/widgets/app_loader.dart';
import 'package:sales_app/widgets/network_aware_wrapper.dart';
import 'package:sales_app/widgets/splash_screen.dart';
import 'package:sales_app/widgets/connectivity_wrapper.dart';
import 'package:sales_app/utils/url_helper.dart';

// Existing routes
import 'package:sales_app/features/notitications/presentation/notifications_screen.dart';


// New: categories/units
import 'package:sales_app/features/categories/presentation/categories_screen.dart';
import 'package:sales_app/features/units/presentation/units_screen.dart';

class PosBusinessApp extends StatefulWidget {
  const PosBusinessApp({super.key});

  @override
  State<PosBusinessApp> createState() => _PosBusinessAppState();
}

class _PosBusinessAppState extends State<PosBusinessApp> {
  bool _showSplash = true;
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    // Get initial route from browser URL
    _initialRoute = _getInitialRoute();
  }

  String? _getInitialRoute() {
    try {
      // For web, get the current URL path and query
      final uri = kIsWeb ? UrlHelper.getBrowserUri() : null;
      if (uri != null && uri.path.contains('reset-password') && uri.queryParameters.containsKey('token')) {
        return '${uri.path}?token=${uri.queryParameters['token']}';
      }
    } catch (e) {
      print('Error getting initial route: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Skip splash if we have a reset password link
    if (_showSplash && _initialRoute == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onComplete: () {
            if (mounted) {
              setState(() {
                _showSplash = false;
              });
              // Force a rebuild after splash to ensure proper state handling
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {}); // Trigger rebuild
                }
              });
            }
          },
        ),
      );
    }

    // Build main app
    final mainApp = MaterialApp(
      title: "Business App",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: _initialRoute ?? '/',
      routes: {
        '/notifications': (_) => const NotificationsScreen(),
        '/settings': (_) => const CurrencySettingsScreen(),
        '/categories': (_) => const _ScopedCategoriesScreen(),
        '/units': (_) => const _ScopedUnitsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle root route
        if (settings.name == '/' || settings.name == null || settings.name!.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => ConnectivityWrapper(
              child: BlocConsumer<AuthBloc, AuthState>(
                listenWhen: (previous, current) {
                  return previous is! AuthAuthenticated && current is AuthAuthenticated;
                },
                listener: (context, state) {
                  // No navigation needed - we're already at '/'
                },
                builder: (context, state) {
                  print('[App] Building with auth state: ${state.runtimeType}');
                  
                  // Show authenticated scaffold
                  if (state is AuthAuthenticated) {
                    print('[App] Showing AdminScaffold');
                    return const NetworkAwareWrapper(
                      child: AdminScaffold(),
                    );
                  }
                  
                  // Show loading during auth check
                  if (state is AuthInitial || state is AuthLoading) {
                    print('[App] Showing loading screen');
                    return Scaffold(
                      backgroundColor: const Color.fromARGB(255, 5, 49, 107),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Show login screen for unauthenticated
                  print('[App] Showing LoginScreen');
                  return const LoginScreen();
                },
              ),
            ),
            settings: settings,
          );
        }
        
        // Handle reset-password route with query parameters
        if (settings.name != null && settings.name!.startsWith('/reset-password')) {
          String? token;
          
          // Try to parse from settings.name first
          try {
            final uri = Uri.parse(settings.name!);
            token = uri.queryParameters['token'];
          } catch (e) {
            // Ignore parsing errors
          }
          
          // If no token found and we're on web, check browser URL
          if ((token == null || token.isEmpty) && kIsWeb) {
            try {
              final browserUri = UrlHelper.getBrowserUri();
              if (browserUri != null) {
                token = browserUri.queryParameters['token'];
              }
            } catch (e) {
              // Ignore parsing errors
            }
          }
          
          if (token != null && token.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(token: token!),
              settings: settings,
            );
          }
        }
        return null;
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const _UnknownRouteScreen(),
        settings: settings,
      ),
    );

    return mainApp;
  }
}

// Provide scoped blocs via context.read in main.dart; here we just build screens
class _ScopedCategoriesScreen extends StatelessWidget {
  const _ScopedCategoriesScreen();

  @override
  Widget build(BuildContext context) => const CategoriesScreen();
}

class _ScopedUnitsScreen extends StatelessWidget {
  const _ScopedUnitsScreen();

  @override
  Widget build(BuildContext context) => const UnitsScreen();
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Route not found'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}