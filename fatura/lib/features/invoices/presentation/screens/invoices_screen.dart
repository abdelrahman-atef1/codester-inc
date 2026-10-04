/// invoices_screen.dart — Invoices list screen
/// Paper Ledger style: cream paper, ink text, forest green FAB.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navInvoices),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: AppColors.inkMuted,
            ),
            SizedBox(height: AppSizes.md),
            Text(
              'لا توجد فواتير بعد',
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
          // TODO: Create new invoice
        },
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }
}