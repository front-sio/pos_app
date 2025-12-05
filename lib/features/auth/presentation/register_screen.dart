import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/widgets/custom_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedGender = 'Male'; // Default value

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (value != _confirmPasswordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _submitRegister() {
    // Unfocus any focused text fields to hide the keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // CORRECTED: Pass arguments by position, matching the constructor in auth_event.dart
      context.read<AuthBloc>().add(RegisterRequested(
        _usernameController.text.trim(),      // 1st argument: username
        _emailController.text.trim(),         // 2nd argument: email
        _firstNameController.text.trim(),      // 3rd argument: firstName
        _lastNameController.text.trim(),       // 4th argument: lastName
        _selectedGender.toLowerCase(),        // 5th argument: gender
        _passwordController.text,              // 6th argument: password
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.kText,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
          // After successful registration, the BLoC emits AuthUnauthenticated.
          // We listen for this state to show a success message and navigate back.
          if (state is AuthUnauthenticated) {
            // This check ensures we only show the success message after a registration attempt,
            // not on initial app load.
            if (_formKey.currentState?.validate() == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registration successful! Please login.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(); // Go back to the login screen
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomInput(
                    controller: _usernameController,
                    label: "Username",
                    prefixIcon: Icons.person,
                    validator: (value) => _validateRequired(value, 'Username'),
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    controller: _emailController,
                    label: "Email",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInput(
                          controller: _firstNameController,
                          label: "First Name",
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) => _validateRequired(value, 'First name'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomInput(
                          controller: _lastNameController,
                          label: "Last Name",
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) => _validateRequired(value, 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: ['Male', 'Female'].map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    controller: _passwordController,
                    label: "Password",
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    controller: _confirmPasswordController,
                    label: "Confirm Password",
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitRegister,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.kPrimary,
                        disabledBackgroundColor: AppColors.kPrimary.withValues(alpha: .7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            )
                          : const Text(
                              "Register",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}