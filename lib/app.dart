import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/features/auth/presentation/login_screen.dart';
import 'package:sales_app/features/settings/presentation/modern_settings_screen.dart';
import 'package:sales_app/features/debug/auth_debug_screen.dart';
import 'package:sales_app/theme/theme_manager.dart';
import 'package:sales_app/widgets/admin_scaffold.dart';
import 'package:sales_app/widgets/app_loader.dart';
import 'package:sales_app/widgets/network_aware_wrapper.dart';
import 'package:sales_app/widgets/splash_screen.dart';
import 'package:sales_app/widgets/connectivity_wrapper.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onComplete: () {
            if (mounted) {
              setState(() {
                _showSplash = false;
              });
            }
          },
        ),
      );
    }

    return AnimatedBuilder(
      animation: ThemeManager(),
      builder: (context, child) {
        final businessColors = ThemeManager().currentBusinessColors;
        
        return MaterialApp(
          title: "Modern Sales App",
          debugShowCheckedModeBanner: false,
          theme: ModernThemeData.lightTheme(businessColors),
          darkTheme: ModernThemeData.darkTheme(businessColors),
          themeMode: ThemeManager().themeMode == AppThemeMode.light
              ? ThemeMode.light
              : ThemeManager().themeMode == AppThemeMode.dark
                  ? ThemeMode.dark
                  : ThemeMode.system,
          routes: {
            '/notifications': (_) => const NotificationsScreen(),
            '/settings': (_) => const ModernSettingsScreen(),
            '/categories': (_) => const _ScopedCategoriesScreen(),
            '/units': (_) => const _ScopedUnitsScreen(),
            '/debug': (_) => const AuthDebugScreen(),
          },
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => const _UnknownRouteScreen(),
            settings: settings,
          ),
          home: ConnectivityWrapper(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return const NetworkAwareWrapper(
                    child: AdminScaffold(),
                  );
                } else if (state is AuthUnauthenticated || state is AuthLoading || state is AuthFailure) {
                  // Stay on login screen for unauthenticated, loading, and failure states
                  // Login screen handles its own loading UI and error messages
                  return const LoginScreen();
                }
                // Initial loading when app starts (AuthInitial)
                return const Scaffold(
                  body: AppLoader.fullscreen(message: 'Preparing app...'),
                );
              },
            ),
          ),
        );
      },
    );
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