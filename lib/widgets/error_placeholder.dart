import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';

/// Generic error placeholder widget for displaying user-friendly error messages
/// Hides technical details from users
class ErrorPlaceholder extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;
  final IconData? icon;

  const ErrorPlaceholder({
    super.key,
    this.onRetry,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.cloud_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re having trouble loading this data.\nPlease check your connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Factory for network timeout errors
  factory ErrorPlaceholder.timeout({VoidCallback? onRetry}) {
    return ErrorPlaceholder(
      icon: Icons.access_time,
      message: 'Request Timeout',
      onRetry: onRetry,
    );
  }

  /// Factory for network connection errors
  factory ErrorPlaceholder.networkError({VoidCallback? onRetry}) {
    return ErrorPlaceholder(
      icon: Icons.wifi_off,
      message: 'No Internet Connection',
      onRetry: onRetry,
    );
  }

  /// Factory for server errors
  factory ErrorPlaceholder.serverError({VoidCallback? onRetry}) {
    return ErrorPlaceholder(
      icon: Icons.error_outline,
      message: 'Server Error',
      onRetry: onRetry,
    );
  }

  /// Factory for empty state
  factory ErrorPlaceholder.empty({String? message, VoidCallback? onRetry}) {
    return ErrorPlaceholder(
      icon: Icons.inbox_outlined,
      message: message ?? 'No Data Available',
      onRetry: onRetry,
    );
  }
}
