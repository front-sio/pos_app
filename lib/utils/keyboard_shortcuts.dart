// lib/utils/keyboard_shortcuts.dart

import 'package:flutter/material.dart';
import 'package:sales_app/widgets/search_dialog.dart';

// Custom Intent for the search action
class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

// Custom Action to handle the intent
class OpenSearchAction extends Action<OpenSearchIntent> {
  final BuildContext context;

  OpenSearchAction(this.context);

  @override
  Object? invoke(OpenSearchIntent intent) {
    // Show the custom search dialog when the intent is invoked
    showDialog(
      context: context,
      builder: (context) => const CustomSearchDialog(),
    );
    return null;
  }
}
