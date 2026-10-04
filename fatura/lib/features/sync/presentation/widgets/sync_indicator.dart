/// sync_indicator.dart — Top bar sync status indicator
///
/// Shows:
///   🟢 "آخر مزامنة: 02:30 ص"  (synced)
///   🔴 "بانتظار المزامنة (5)" (pending changes)
///   🔄 "جاري المزامنة..."     (syncing)
///
/// onPressed → opens sync screen
/// Paper Ledger design: small pill-shaped badge.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/sync_providers.dart';

/// Sync indicator badge for the top bar.
///
/// Shows current sync status as a tappable pill.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingChangesProvider);
    final config = ref.watch(syncConfigProvider);

    // Don't show if sync is not configured.
    if (!config.isConfigured) return const SizedBox.shrink();

    final indicator = _buildIndicator(syncState, pendingCount);

    return GestureDetector(
      onTap: () => context.push('/sync'),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm + 2, vertical: AppSizes.xs + 1),
        decoration: BoxDecoration(
          color: indicator.bgColor,
          border: Border.all(color: indicator.borderColor, width: 1),
          borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator.icon,
            const SizedBox(width: AppSizes.xs),
            Text(
              indicator.label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w600,
                color: indicator.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _IndicatorData _buildIndicator(SyncState syncState, int pendingCount) {
    switch (syncState.status) {
      case SyncStatus.syncing:
        return _IndicatorData(
          icon: const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.forest,
            ),
          ),
          label: 'جاري المزامنة...',
          bgColor: AppColors.forest.withValues(alpha: 0.1),
          borderColor: AppColors.forest.withValues(alpha: 0.3),
          textColor: AppColors.forest,
        );

      case SyncStatus.error:
        return _IndicatorData(
          icon: const Icon(Icons.error_outline,
              size: 14, color: AppColors.stampRed),
          label: syncState.errorMessage != null &&
                  syncState.errorMessage!.isNotEmpty
              ? 'خطأ في المزامنة'
              : 'فشلت المزامنة',
          bgColor: AppColors.stampRed.withValues(alpha: 0.1),
          borderColor: AppColors.stampRed.withValues(alpha: 0.3),
          textColor: AppColors.stampRed,
        );

      case SyncStatus.success:
        final timeStr = _formatTime(syncState.lastSyncTime);
        return _IndicatorData(
          icon: const Icon(Icons.check_circle,
              size: 14, color: AppColors.forest),
          label: 'آخر مزامنة: $timeStr',
          bgColor: AppColors.forest.withValues(alpha: 0.08),
          borderColor: AppColors.forest.withValues(alpha: 0.25),
          textColor: AppColors.forest,
        );

      case SyncStatus.idle:
        if (pendingCount > 0) {
          return _IndicatorData(
            icon: const Icon(Icons.sync_problem,
                size: 14, color: AppColors.stampRed),
            label: 'بانتظار المزامنة ($pendingCount)',
            bgColor: AppColors.ochre.withValues(alpha: 0.1),
            borderColor: AppColors.ochre.withValues(alpha: 0.3),
            textColor: AppColors.ochre,
          );
        }
        // All synced, no pending.
        final timeStr = syncState.lastSyncTime != null
            ? _formatTime(syncState.lastSyncTime)
            : 'لا مزامنة بعد';
        return _IndicatorData(
          icon: const Icon(Icons.check_circle,
              size: 14, color: AppColors.forest),
          label: 'متزامن — $timeStr',
          bgColor: AppColors.forest.withValues(alpha: 0.08),
          borderColor: AppColors.forest.withValues(alpha: 0.25),
          textColor: AppColors.forest,
        );
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }
}

/// Internal data class for indicator display state.
class _IndicatorData {
  final Widget icon;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _IndicatorData({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}