// lib/widgets/custom_search_dialog.dart

import 'package:flutter/material.dart';

class CustomSearchDialog extends StatefulWidget {
  const CustomSearchDialog({super.key});

  @override
  State<CustomSearchDialog> createState() => _CustomSearchDialogState();
}

class _CustomSearchDialogState extends State<CustomSearchDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Request focus on the text field when the dialog is shown
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: 600, // Adjust size as needed
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Row
            Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search products, orders, customers...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      // Handle the search action here
                      print('Searching for: $value');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            // Example of recent searches section
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 20),
                    title: const Text('Product X'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to the search result
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 20),
                    title: const Text('Customer Y'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to the search result
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
