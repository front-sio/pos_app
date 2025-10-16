import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/features/auth/presentation/login_screen.dart';
import 'package:sales_app/widgets/admin_scaffold.dart';
import 'package:sales_app/theme/app_theme.dart';
import 'package:sales_app/widgets/app_loader.dart';

class PosBusinessApp extends StatelessWidget {
  const PosBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "POS Business App",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
          // AuthInitial or any transient/unknown state
          return const Scaffold(
            body: AppLoader.fullscreen(message: 'Preparing app...'),
          );
        },
      ),
    );
  }
}