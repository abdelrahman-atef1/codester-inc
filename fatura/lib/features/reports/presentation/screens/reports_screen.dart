/// reports_screen.dart — Reports hub screen
///
/// Shows links to daily/monthly reports.
/// Paper Ledger style: cream paper, ink text.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navReports),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        children: [
          _ReportTile(
            icon: Icons.today,
            title: AppStrings.dailyReport,
            subtitle: 'إجمالي المبيعات، عدد الفواتير، أكثر المنتجات مبيعاً',
            color: AppColors.forest,
            onTap: () => context.push('/reports/daily'),
          ),
          const SizedBox(height: AppSizes.sm),
          _ReportTile(
            icon: Icons.calendar_month,
            title: AppStrings.monthlyReport,
            subtitle: 'رسم بياني للمبيعات اليومية خلال الشهر',
            color: AppColors.indigo,
            onTap: () {
              // TODO: Monthly report route
            },
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color.fromRGBO(color.r.round(), color.g.round(), color.b.round(), 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                border: Border.all(color: color, width: 1.2),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontLG,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontXS,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.inkMuted, size: 20),
          ],
        ),
      ),
    );
  }
}