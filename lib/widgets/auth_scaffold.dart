import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double horizontalPadding;
    if (width >= 1024) {
      horizontalPadding = 64;
    } else if (width >= 600) {
      horizontalPadding = 32;
    } else {
      horizontalPadding = 16;
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: child,
          ),
        ),
      ),
    );
  }
}
