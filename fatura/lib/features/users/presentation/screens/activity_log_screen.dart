/// activity_log_screen.dart — Activity Log (US-022)
///
/// Owner-only screen showing a chronological list of all activities.
/// Filter chips: All / Sale / Inventory / Login.
/// Paper Ledger cards with action-specific icons and colors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart' as db;
import '../../../auth/providers/auth_providers.dart';
import '../../../inventory/providers/inventory_providers.dart'
    show activityLogDaoProvider;

// ─── Activity Log Provider ───

/// Reactive stream of all activity logs.
final activityLogsProvider =
    StreamProvider<List<db.ActivityLogData>>((ref) {
  final dao = ref.watch(activityLogDaoProvider);
  return dao.watchAllLogs();
});

// ─── Filter enum ───

enum ActivityFilter {
  all,
  sale,
  inventory,
  login,
}

const _filterLabels = {
  ActivityFilter.all: AppStrings.activityAll,
  ActivityFilter.sale: AppStrings.activitySale,
  ActivityFilter.inventory: AppStrings.activityInventory,
  ActivityFilter.login: AppStrings.activityLogin,
};

// ─── Action metadata ───

class _ActionMeta {
  final IconData icon;
  final Color color;
  const _ActionMeta(this.icon, this.color);
}

const _actionMeta = <String, _ActionMeta>{
  'sale': _ActionMeta(Icons.point_of_sale, AppColors.forest),
  'add_product': _ActionMeta(Icons.add_box, AppColors.forest),
  'edit_product': _ActionMeta(Icons.edit, AppColors.ochre),
  'delete_product': _ActionMeta(Icons.delete, AppColors.stampRed),
  'login': _ActionMeta(Icons.login, AppColors.indigo),
  'add': _ActionMeta(Icons.person_add, AppColors.forest),
  'edit': _ActionMeta(Icons.edit, AppColors.ochre),
  'delete': _ActionMeta(Icons.delete, AppColors.stampRed),
};

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  ActivityFilter _filter = ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    // Owner-only guard
    final session = ref.watch(authSessionProvider);
    if (!session.isOwner) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.activityLog)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.stampRed),
              SizedBox(height: AppSizes.md),
              Text(
                AppStrings.ownerOnly,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontLG,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final logsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.activityLog),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMD,
              vertical: AppSizes.paddingSM,
            ),
            child: Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: ActivityFilter.values.map((f) {
                final isSelected = _filter == f;
                return FilterChip(
                  label: Text(_filterLabels[f]!),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: AppColors.forest.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.forest,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.forest
                        : AppColors.ledgerBorder,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Log list
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.forest),
              ),
              error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(fontFamily: 'Cairo')),
              ),
              data: (logs) {
                final filtered = _applyFilter(logs);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 64, color: AppColors.inkMuted),
                        SizedBox(height: AppSizes.md),
                        Text(
                          AppStrings.noActivity,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontLG,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered[index];
                    return _ActivityLogCard(log: log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<db.ActivityLogData> _applyFilter(List<db.ActivityLogData> logs) {
    switch (_filter) {
      case ActivityFilter.all:
        return logs;
      case ActivityFilter.sale:
        return logs.where((l) =>
            l.action == 'sale' || l.action.contains('sale')).toList();
      case ActivityFilter.inventory:
        return logs.where((l) =>
            l.action.contains('product') ||
            l.entityType == 'product').toList();
      case ActivityFilter.login:
        return logs.where((l) =>
            l.action == 'login' || l.action == 'logout').toList();
    }
  }
}

// ─── Activity Log Card ───

class _ActivityLogCard extends StatelessWidget {
  final db.ActivityLogData log;
  const _ActivityLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final meta = _actionMeta[log.action] ??
        _ActionMeta(Icons.history, AppColors.inkMuted);

    final timeStr = _formatTime(log.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meta.color.withValues(alpha: 0.15),
                border: Border.all(color: meta.color, width: 1.5),
              ),
              child: Icon(meta.icon, size: 20, color: meta.color),
            ),
            const SizedBox(width: AppSizes.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.details ?? log.action,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        log.action,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontXS,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (log.entityType != null) ...[
                        Text(
                          '· ${log.entityType}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontXS,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Timestamp
            Text(
              timeStr,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}