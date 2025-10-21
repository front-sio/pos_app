import 'package:flutter/material.dart';
import 'package:sales_app/features/auth/presentation/login_screen.dart';
import '../../constants/colors.dart';
import '../../widgets/auth_scaffold.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE63946), Color(0xFF457B9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    const FlutterLogo(size: 100),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      "Welcome to",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.kTextSecondary,
                          ),
                    ),
                    Text(
                      "Tuite Sport Business",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.kText,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      "Manage your teams, schedule matches, and grow your sports business all in one place.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.kTextSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Login button
                    ElevatedButton.icon(
                      onPressed: () => _navigate(context, const LoginScreen()),
                      icon: const Icon(Icons.login),
                      label: const Text("Login"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
