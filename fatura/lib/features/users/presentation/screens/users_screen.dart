/// users_screen.dart — User management screen
/// Paper Ledger style: cream paper, ink text, forest green FAB.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: AppColors.inkMuted,
            ),
            SizedBox(height: AppSizes.md),
            Text(
              'لا يوجد موظفون بعد',
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
          // TODO: Add user
        },
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}