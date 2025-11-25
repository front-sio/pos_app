import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined, 
            size: 64, 
            color: AppColors.kTextSecondary.withOpacity(0.5)
          ),
          const SizedBox(height: AppSizes.padding),
          Text(
            'Cart is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.kTextSecondary
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a barcode or select a product',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.kTextSecondary
            ),
          ),
        ],
      ),
    );
  }
}