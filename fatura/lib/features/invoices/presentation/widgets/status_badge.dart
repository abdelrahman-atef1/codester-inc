/// status_badge.dart — Status badge widget for invoice status
///
/// Paper Ledger style: bordered chips, no shadows.
/// Completed → forest green, Draft → amber/ochre, Refunded → stamp red.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        border: Border.all(color: config.borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config(String status) {
    switch (status) {
      case 'completed':
        return const _BadgeConfig(
          label: 'مكتملة',
          icon: Icons.check_circle_outline,
          bgColor: Color(0x1A2D6A4F), // 10% forest
          borderColor: AppColors.forest,
          textColor: AppColors.forestDark,
        );
      case 'draft':
        return const _BadgeConfig(
          label: 'مسودة',
          icon: Icons.edit_note,
          bgColor: Color(0x1AB8860B), // 10% ochre
          borderColor: AppColors.ochre,
          textColor: AppColors.ochre,
        );
      case 'refunded':
        return const _BadgeConfig(
          label: 'مسترجعة',
          icon: Icons.undo,
          bgColor: Color(0x1AB83A3A), // 10% stamp red
          borderColor: AppColors.stampRed,
          textColor: AppColors.stampRed,
        );
      default:
        return const _BadgeConfig(
          label: 'غير معروف',
          icon: Icons.help_outline,
          bgColor: Color(0x1A8A8270),
          borderColor: AppColors.inkMuted,
          textColor: AppColors.inkMuted,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}