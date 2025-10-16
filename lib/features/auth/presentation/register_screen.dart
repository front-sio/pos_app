import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/widgets/auth_scaffold.dart';
import 'package:sales_app/widgets/custom_field.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final genderController = TextEditingController();

  void _register() {
    context.read<AuthBloc>().add(
          RegisterRequested(
            usernameController.text,
            emailController.text,
            firstNameController.text,
            lastNameController.text,
            genderController.text,
            passwordController.text,
          ),
        );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registration Successful!"), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    "Create an Account",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kText,
                        ),
                  ),
                  const SizedBox(height: 32),
                  CustomInput(controller: usernameController, label: "Username", prefixIcon: Icons.person_outline),
                  const SizedBox(height: 16),
                  CustomInput(controller: emailController, label: "Email", prefixIcon: Icons.email_outlined),
                  const SizedBox(height: 16),
                  CustomInput(controller: firstNameController, label: "First Name", prefixIcon: Icons.person_outline),
                  const SizedBox(height: 16),
                  CustomInput(controller: lastNameController, label: "Last Name", prefixIcon: Icons.person_outline),
                  const SizedBox(height: 16),
                  CustomInput(controller: genderController, label: "Gender", prefixIcon: Icons.person_outline),
                  const SizedBox(height: 16),
                  CustomInput(controller: passwordController, label: "Password", prefixIcon: Icons.lock_outline, isPassword: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: AppColors.kPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: state is AuthLoading
                              ? SizedBox(height: 40, width: 40, child: Lottie.asset('assets/lottie/loader.json', repeat: true))
                              : const Text("Register", style: TextStyle(fontSize: 16, color: Colors.white)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.kTextSecondary),
                      ),
                      TextButton(
                        onPressed: _goToLogin,
                        child: Text("Login", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.kPrimary, fontWeight: FontWeight.bold)),
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
