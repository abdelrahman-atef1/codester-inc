/// inventory_screen.dart — Product inventory screen (placeholder)
/// Paper Ledger style.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navInventory),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.forest),
            onPressed: () {
              // TODO: Open barcode scanner to add product
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: AppColors.inkMuted,
            ),
            SizedBox(height: AppSizes.md),
            Text(
              'لا توجد منتجات بعد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontLG,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add product
        },
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }
}