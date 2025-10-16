import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/widgets/auth_scaffold.dart';
import 'package:sales_app/widgets/custom_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      // The AuthScaffold already contains an AppBar, which automatically adds a back button.
      // However, it is possible to override the leading action if needed.
      // If AuthScaffold does not have an AppBar, you can add it explicitly.
      // For this example, we will assume AuthScaffold handles the AppBar,
      // but we will add a TextButton inside the Column for a more explicit UI control.
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Text(
                "Forgot Password",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.kText,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email to receive a password reset link.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.kTextSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CustomInput(
                label: "Email",
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Write logic to send password reset email
                    // For now, we just pop the screen
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Send Reset Link", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              // Add a button for users who do not need to reset
              TextButton(
                onPressed: () {
                  // Navigate back to the login screen
                  Navigator.pop(context);
                },
                child: Text(
                  "Never mind, take me back to login",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.kPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
