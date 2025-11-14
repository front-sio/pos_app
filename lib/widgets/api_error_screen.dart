import 'package:flutter/material.dart';
import 'package:sales_app/config/config.dart';

class ApiErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;
  final String? endpoint;

  const ApiErrorScreen({
    super.key,
    this.onRetry,
    this.errorMessage,
    this.endpoint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 60,
                    color: Colors.red[400],
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Service Unavailable',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Unable to connect to server',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Error Details Card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                               color: Colors.orange[700], 
                               size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Error Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (errorMessage != null) ...[
                        _InfoRow(
                          icon: Icons.error_outline,
                          label: 'Message:',
                          value: errorMessage!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      _InfoRow(
                        icon: Icons.dns_outlined,
                        label: 'Server:',
                        value: AppConfig.baseUrl,
                      ),
                      
                      if (endpoint != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.api_outlined,
                          label: 'Endpoint:',
                          value: endpoint!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Possible Causes
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, 
                               color: Colors.blue[700], 
                               size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Possible Causes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CauseItem(
                        icon: Icons.wifi_off,
                        text: 'Network connection is weak or unavailable',
                      ),
                      const SizedBox(height: 10),
                      _CauseItem(
                        icon: Icons.cloud_off,
                        text: 'Server cannot be reached at the moment',
                      ),
                      const SizedBox(height: 10),
                      _CauseItem(
                        icon: Icons.construction,
                        text: 'Service is down for maintenance',
                      ),
                      const SizedBox(height: 10),
                      _CauseItem(
                        icon: Icons.access_time,
                        text: 'Request timed out (connection too slow)',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                  ),

                const SizedBox(height: 16),

                // Help Text
                Text(
                  'If the problem persists, please contact technical support',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CauseItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CauseItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[900],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
