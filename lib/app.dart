import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/features/auth/presentation/login_screen.dart';
import 'package:sales_app/features/settings/presentation/currency_settings_screen.dart';
import 'package:sales_app/theme/app_theme.dart';
import 'package:sales_app/widgets/admin_scaffold.dart';
import 'package:sales_app/widgets/app_loader.dart';

// Routes
import 'package:sales_app/features/notitications/presentation/notifications_screen.dart';


class PosBusinessApp extends StatelessWidget {
  const PosBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "POS Business App",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Named routes used by AppBar actions
      routes: {
        '/notifications': (_) => const NotificationsScreen(),
        '/settings': (_) => const CurrencySettingsScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const _UnknownRouteScreen(),
        settings: settings,
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const AdminScaffold();
          } else if (state is AuthUnauthenticated) {
            return const LoginScreen();
          } else if (state is AuthLoading) {
            return const Scaffold(
              body: AppLoader.fullscreen(message: 'Signing you in...'),
            );
          }
          return const Scaffold(
            body: AppLoader.fullscreen(message: 'Preparing app...'),
          );
        },
      ),
    );
  }
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