// lib/utils/helpers.dart


import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sales_app/utils/api_error_handler.dart';

/// Shows a toast message to the user.
///
/// Requires the `fluttertoast` package to be added to `pubspec.yaml`.
void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black54,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

/// Shows a snackbar message at the bottom of the screen.
void showSnackbar(BuildContext context, String message, {Color color = Colors.green}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
    ),
  );
}

/// Shows an error snackbar with user-friendly message from API error
void showErrorSnackbar(BuildContext context, dynamic error) {
  String message;
  
  if (error is ApiException) {
    message = error.message;
  } else {
    message = ApiErrorHandler.getErrorMessage(error);
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Sawa',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// Shows an error dialog with user-friendly message
void showErrorDialog(BuildContext context, dynamic error, {VoidCallback? onRetry}) {
  String message;
  String title = 'Tatizo';
  
  if (error is ApiException) {
    message = error.message;
    if (error.isNetworkError) {
      title = 'Tatizo la Mtandao';
    } else if (error.isServerError) {
      title = 'Tatizo la Server';
    } else if (error.isTimeoutError) {
      title = 'Muda Umeisha';
    }
  } else {
    message = ApiErrorHandler.getErrorMessage(error);
  }
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text('Jaribu Tena'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sawa'),
        ),
      ],
    ),
  );
}

/// Formats a number as a currency string.
///
/// Uses the provided currency symbol and supports a fixed number of decimal places.
String formatCurrency(num amount, {String symbol = 'KES', int decimalPlaces = 2}) {
  return '$symbol ${amount.toStringAsFixed(decimalPlaces)}';
}

/// Checks the network connection status.
///
/// Requires the `connectivity_plus` package.
Future<bool> checkNetworkStatus() async {
  final connectivityResult = await (Connectivity().checkConnectivity());
  return connectivityResult != ConnectivityResult.none;
}

/// Navigates to a new screen.
///
/// Pushes the new screen onto the navigation stack.
void navigateTo(BuildContext context, Widget screen) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

/// Navigates to a new screen and replaces the current one.
void navigateAndReplace(BuildContext context, Widget screen) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}
