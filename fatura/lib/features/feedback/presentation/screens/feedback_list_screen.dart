/// feedback_list_screen.dart — Owner-only list of all feedbacks
///
/// Paper Ledger style: cream paper, bordered cards, status badges with
/// stamp red (new), amber (read), forest green (resolved).
/// Owner can filter by type and change status.
library;

import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/database/database.dart';
import '../../domain/feedback_type.dart';
import '../../providers/feedback_providers.dart';

class FeedbackListScreen extends ConsumerWidget {
  const FeedbackListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbacksAsync = ref.watch(filteredFeedbacksProvider);
    final currentFilter = ref.watch(feedbackFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الملاحظات والاقتراحات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // ─── Filter Bar ───
          _FilterBar(
            currentFilter: currentFilter,
            onFilterChanged: (f) {
              HapticFeedback.selectionClick();
              ref.read(feedbackFilterProvider.notifier).state = f;
            },
          ),
          const Divider(color: AppColors.ledgerLine, thickness: 1, height: 1),

          // ─── List ───
          Expanded(
            child: feedbacksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'خطأ في تحميل الملاحظات: $e',
                  style: const TextStyle(fontFamily: 'Cairo', color: AppColors.stampRed),
                ),
              ),
              data: (feedbacks) {
                if (feedbacks.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  itemCount: feedbacks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    return _FeedbackCard(
                      feedback: feedbacks[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Filter Bar
// ═══════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  final String? currentFilter;
  final ValueChanged<String?> onFilterChanged;

  const _FilterBar({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  static const _filters = <_FilterOption>[
    _FilterOption(label: 'الكل', value: null),
    _FilterOption(label: 'مشاكل', value: 'bug'),
    _FilterOption(label: 'ميزات', value: 'feature_request'),
    _FilterOption(label: 'تحسينات', value: 'improvement'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD, vertical: AppSizes.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isSelected = currentFilter == f.value;
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.xs),
              child: GestureDetector(
                onTap: () => onFilterChanged(f.value),
                child: AnimatedContainer(
                  duration: AppSizes.durationShort,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.forest.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
                    border: Border.all(
                      color: isSelected ? AppColors.forest : AppColors.ledgerBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontSM,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.forest : AppColors.inkLight,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String? value;
  const _FilterOption({required this.label, required this.value});
}

// ═══════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ledgerBorder, width: 2),
              ),
              child: const Icon(
                Icons.feedback_outlined,
                color: AppColors.inkMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'لا توجد ملاحظات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXL,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            const Text(
              'ستظهر هنا الملاحظات والاقتراحات المرسلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Feedback Card
// ═══════════════════════════════════════════════════════════════

class _FeedbackCard extends ConsumerWidget {
  final Feedback feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = FeedbackType.fromDb(feedback.type);
    final status = FeedbackStatus.fromDb(feedback.status);
    final priority = FeedbackPriority.fromDb(feedback.priority);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Row 1: Type icon + Title + Status badge ───
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _typeColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                  border: Border.all(color: _typeColor(type).withValues(alpha: 0.3), width: 1),
                ),
                child: Icon(_typeIcon(type), color: _typeColor(type), size: 18),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  feedback.title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          // ─── Row 2: Description ───
          Text(
            feedback.description,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontSM,
              color: AppColors.inkLight,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSizes.sm),

          // ─── Row 3: Meta + Actions ───
          Row(
            children: [
              // Type label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor(type).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                ),
                child: Text(
                  type.labelAr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w600,
                    color: _typeColor(type),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              // Priority (if set)
              if (priority != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(priority).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                  ),
                  child: Text(
                    'أولوية: ${priority.labelAr}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontXS,
                      fontWeight: FontWeight.w600,
                      color: _priorityColor(priority),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
              ],
              // Date
              Text(
                _formatDate(feedback.createdAt),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontXS,
                  color: AppColors.inkMuted,
                ),
              ),

              const Spacer(),

              // ─── Status change popup ───
              _StatusPopupMenu(
                feedbackId: feedback.id,
                currentStatus: status,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───

  Color _typeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return AppColors.stampRed;
      case FeedbackType.featureRequest:
        return AppColors.indigo;
      case FeedbackType.improvement:
        return AppColors.forest;
    }
  }

  IconData _typeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Icons.bug_report;
      case FeedbackType.featureRequest:
        return Icons.lightbulb;
      case FeedbackType.improvement:
        return Icons.tune;
    }
  }

  Color _priorityColor(FeedbackPriority p) {
    switch (p) {
      case FeedbackPriority.low:
        return AppColors.forest;
      case FeedbackPriority.medium:
        return AppColors.ochre;
      case FeedbackPriority.high:
        return AppColors.stampRed;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════
// Status Badge
// ═══════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final FeedbackStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontXS,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(FeedbackStatus s) {
    switch (s) {
      case FeedbackStatus.new_:
        return AppColors.stampRed;
      case FeedbackStatus.read:
        return AppColors.ochre;
      case FeedbackStatus.resolved:
        return AppColors.forest;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Status Popup Menu (Owner actions)
// ═══════════════════════════════════════════════════════════════

class _StatusPopupMenu extends ConsumerWidget {
  final int feedbackId;
  final FeedbackStatus currentStatus;

  const _StatusPopupMenu({
    required this.feedbackId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<FeedbackStatus>(
      icon: const Icon(Icons.more_vert, color: AppColors.inkMuted, size: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        side: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
      ),
      color: AppColors.card,
      onSelected: (newStatus) async {
        HapticFeedback.selectionClick();
        await ref.read(feedbackStatusProvider.notifier).updateStatus(
              feedbackId,
              newStatus,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تحديث الحالة إلى: ${newStatus.labelAr}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      itemBuilder: (context) => FeedbackStatus.values.map((s) {
        final isSelected = s == currentStatus;
        return PopupMenuItem<FeedbackStatus>(
          value: s,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18,
                color: isSelected ? AppColors.forest : AppColors.inkMuted,
              ),
              const SizedBox(width: 8),
              Text(
                s.labelAr,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontSM,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.forest : AppColors.ink,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}