import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/widgets/admin_scaffold.dart';
import 'package:sales_app/widgets/auth_scaffold.dart';
import 'package:sales_app/widgets/custom_field.dart';

import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form + focus
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Validation helpers
  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    // Basic email regex
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _goToRegister() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RegisterScreen(),
        transitionsBuilder: (context, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _submitLogin() {
    // Validate form before dispatch
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      HapticFeedback.lightImpact();
      return;
    }
    final email = emailController.text.trim();
    final password = passwordController.text;
    context.read<AuthBloc>().add(LoginRequested(email, password));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login Successful!"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminScaffold()),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    "POS Business App",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kText,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Login to continue managing your business",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.kTextSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email
                  CustomInput(
                    controller: emailController,
                    label: "Email",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    focusNode: _emailFocus,
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password
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

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _goToForgotPassword,
                      child: Text(
                        "Forgot password?",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.kPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : _submitLogin,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: AppColors.kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: Lottie.asset(
                                    'assets/lottie/loader.json',
                                    repeat: true,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.kTextSecondary),
                      ),
                      TextButton(
                        onPressed: _goToRegister,
                        child: Text(
                          "Register",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.kPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}