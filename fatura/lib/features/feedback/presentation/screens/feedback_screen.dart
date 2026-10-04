/// feedback_screen.dart — Submit feedback (bug / feature / improvement)
///
/// Paper Ledger style: cream paper, bordered cards, underline inputs,
/// forest green submit button, RTL Cairo typography.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/feedback_type.dart';
import '../../providers/feedback_providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  FeedbackType _selectedType = FeedbackType.bug;
  FeedbackPriority? _selectedPriority;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── Palette per type ───
  Color get _typeColor {
    switch (_selectedType) {
      case FeedbackType.bug:
        return AppColors.stampRed;
      case FeedbackType.featureRequest:
        return AppColors.indigo;
      case FeedbackType.improvement:
        return AppColors.forest;
    }
  }

  IconData get _typeIcon {
    switch (_selectedType) {
      case FeedbackType.bug:
        return Icons.bug_report;
      case FeedbackType.featureRequest:
        return Icons.lightbulb;
      case FeedbackType.improvement:
        return Icons.tune;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final success = await ref.read(feedbackSubmitProvider.notifier).submit(
          type: _selectedType,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _selectedPriority,
        );

    if (mounted) {
      if (success) {
        setState(() => _submitted = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء الإرسال. حاول مرة أخرى.'),
            backgroundColor: AppColors.stampRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(feedbackSubmitProvider);

    // ─── Success view ───
    if (_submitted) {
      return _SuccessView(
        onAnother: () {
          setState(() {
            _submitted = false;
            _titleController.clear();
            _descriptionController.clear();
            _selectedType = FeedbackType.bug;
            _selectedPriority = null;
          });
        },
      );
    }

    // ─── Form view ───
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('أرسل ملاحظة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          children: [
            // ─── Header ───
            _buildHeader(),
            const SizedBox(height: AppSizes.lg),

            // ─── Type Chips ───
            _buildSectionLabel('نوع الملاحظة'),
            const SizedBox(height: AppSizes.sm),
            _buildTypeChips(),
            const SizedBox(height: AppSizes.lg),

            // ─── Title ───
            _buildSectionLabel('العنوان'),
            const SizedBox(height: AppSizes.sm),
            _buildTitleField(),
            const SizedBox(height: AppSizes.lg),

            // ─── Description ───
            _buildSectionLabel('الوصف التفصيلي'),
            const SizedBox(height: AppSizes.sm),
            _buildDescriptionField(),
            const SizedBox(height: AppSizes.lg),

            // ─── Priority (optional) ───
            _buildSectionLabel('الأولوية (اختياري)'),
            const SizedBox(height: AppSizes.sm),
            _buildPriorityChips(),
            const SizedBox(height: AppSizes.xl),

            // ─── Submit Button ───
            _buildSubmitButton(isSubmitting),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Widgets
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
              border: Border.all(color: _typeColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 24),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رأيك يهمنا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'ساعدنا في تحسين فاتورة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w600,
        color: AppColors.inkLight,
      ),
    );
  }

  Widget _buildTypeChips() {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: FeedbackType.values.map((type) {
        final isSelected = type == _selectedType;
        final color = _colorForType(type);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedType = type);
          },
          child: AnimatedContainer(
            duration: AppSizes.durationShort,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
              border: Border.all(
                color: isSelected ? color : AppColors.ledgerBorder,
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForType(type),
                  size: 18,
                  color: isSelected ? color : AppColors.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  type.labelAr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _colorForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return AppColors.stampRed;
      case FeedbackType.featureRequest:
        return AppColors.indigo;
      case FeedbackType.improvement:
        return AppColors.forest;
    }
  }

  IconData _iconForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Icons.bug_report;
      case FeedbackType.featureRequest:
        return Icons.lightbulb;
      case FeedbackType.improvement:
        return Icons.tune;
    }
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      maxLength: 200,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الرجاء إدخال عنوان';
        }
        if (value.trim().length < 3) {
          return 'العنوان قصير جداً';
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: 'اكتب عنواناً مختصراً',
        prefixIcon: Icon(Icons.title, color: AppColors.forest),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 6,
      minLines: 4,
      textInputAction: TextInputAction.newline,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الرجاء إدخال الوصف';
        }
        if (value.trim().length < 10) {
          return 'الوصف قصير جداً (10 أحرف على الأقل)';
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: 'صف المشكلة أو الاقتراح بالتفصيل...',
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.description, color: AppColors.forest),
      ),
    );
  }

  Widget _buildPriorityChips() {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: [
        // None / skip
        _priorityChip(
          label: 'بدون',
          selected: _selectedPriority == null,
          color: AppColors.inkMuted,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedPriority = null);
          },
        ),
        ...FeedbackPriority.values.map((p) {
          final color = _priorityColor(p);
          return _priorityChip(
            label: p.labelAr,
            selected: _selectedPriority == p,
            color: color,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedPriority = p);
            },
          );
        }),
      ],
    );
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

  Widget _priorityChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSizes.durationShort,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          border: Border.all(
            color: selected ? color : AppColors.ledgerBorder,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontSM,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : AppColors.inkLight,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isSubmitting) {
    return SizedBox(
      height: AppSizes.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            side: const BorderSide(color: AppColors.forestDark, width: 1),
          ),
          elevation: 0,
        ),
        icon: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : const Icon(Icons.send, size: 20),
        label: Text(
          isSubmitting ? 'جاري الإرسال...' : 'إرسال الملاحظة',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontLG,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Success View
// ═══════════════════════════════════════════════════════════════

class _SuccessView extends StatelessWidget {
  final VoidCallback onAnother;

  const _SuccessView({required this.onAnother});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('أرسل ملاحظة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stamp-style success icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.forest, width: 3),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.forest,
                  size: 56,
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              const Text(
                'شكراً على ملاحظاتك',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontXXL,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'ملاحظاتك تساعدنا في تحسين فاتورة باستمرار.\nسنقوم بمراجعتها في أقرب وقت.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontMD,
                  color: AppColors.inkMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
              // Back to settings
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text(
                    'العودة للإعدادات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontLG,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // Submit another
              TextButton.icon(
                onPressed: onAnother,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'إرسال ملاحظة أخرى',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}