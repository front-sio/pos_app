// lib/utils/helpers.dart


import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
