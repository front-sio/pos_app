import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/features/auth/presentation/login_background_painter.dart';
import 'package:sales_app/widgets/admin_scaffold.dart';
import 'package:sales_app/widgets/auth_scaffold.dart';
import 'package:sales_app/widgets/custom_field.dart';

import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Controllers
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  // Form + focus
  final _formKey = GlobalKey<FormState>();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  // Validation helpers
  String? _validateIdentifier(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Email or Username is required';
    }
    // Simple email regex check
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (v.contains('@') && !emailRegex.hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _submitLogin() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      HapticFeedback.lightImpact();
      return;
    }
    final identifier = identifierController.text.trim();
    final password = passwordController.text;
    context.read<AuthBloc>().add(LoginRequested(identifier, password));
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full page animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: LoginBackgroundPainter(animation: _animation),
                );
              },
            ),
          ),
          // Login card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            "POS Business App",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kText,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please login to continue",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.kTextSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Identifier field
                          CustomInput(
                            controller: identifierController,
                            label: "Email or Username",
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            focusNode: _identifierFocus,
                            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            validator: _validateIdentifier,
                          ),
                          const SizedBox(height: 24),

                          // Password field
                          CustomInput(
                            controller: passwordController,
                            label: "Password",
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            focusNode: _passwordFocus,
                            onFieldSubmitted: (_) => _submitLogin(),
                            validator: _validatePassword,
                          ),

                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _goToForgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Forgot password?",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.kPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: BlocConsumer<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state is AuthFailure) {
                                  // Show error immediately before navigation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(state.error)),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              },
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return ElevatedButton(
                                  onPressed: isLoading ? null : _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    backgroundColor: AppColors.kPrimary,
                                    disabledBackgroundColor: AppColors.kPrimary.withOpacity(0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              "Logging in...",
                                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Login",
                                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                );
                              },
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
          ),
          // BlocListener for navigation only
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                // Navigate directly without showing loader dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScaffold()),
                );
              }
            },
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
