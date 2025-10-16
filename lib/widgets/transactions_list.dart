// lib/widgets/transactions_list.dart
import 'package:flutter/material.dart';
import 'package:sales_app/constants/sizes.dart';

class TransactionsList extends StatelessWidget {
  const TransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Row(
              // ...
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              return ListTile(
                // ... (rest of the list tile code)
              );
            },
          ),
        ],
      ),
    );
  }
}

