/// success_dialog.dart — Checkout success overlay
///
/// Animation spec §4b:
/// - Dimmed bg fade-in (200ms)
/// - Checkmark draw via CustomPaint + path metric (500ms)
/// - Checkmark color: stamp red → forest green
/// - "تم البيع" slide up + fade (300ms)
/// - Confetti burst (1200ms) — gated behind disableAnimations check
/// - Action buttons staggered fade+slide (50ms apart)
/// - Overlay dismiss: fade + scale down (250ms)
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';

class SuccessDialog extends StatefulWidget {
  final String invoiceNumber;
  final double total;
  final double change;
  final String currencySymbol;
  final VoidCallback onNewSale;
  final VoidCallback? onPrint;
  final VoidCallback? onShare;

  const SuccessDialog({
    super.key,
    required this.invoiceNumber,
    required this.total,
    this.change = 0,
    this.currencySymbol = 'ج.م',
    required this.onNewSale,
    this.onPrint,
    this.onShare,
  });

  /// Show the success dialog as a full-screen overlay
  static Future<void> show(
    BuildContext context, {
    required String invoiceNumber,
    required double total,
    double change = 0,
    String currencySymbol = 'ج.م',
    required VoidCallback onNewSale,
    VoidCallback? onPrint,
    VoidCallback? onShare,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => SuccessDialog(
        invoiceNumber: invoiceNumber,
        total: total,
        change: change,
        currencySymbol: currencySymbol,
        onNewSale: onNewSale,
        onPrint: onPrint,
        onShare: onShare,
      ),
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _confettiController;
  late final AnimationController _textController;
  late final AnimationController _buttonController;
  late final Animation<double> _checkProgress;
  late final Animation<double> _colorTween;

  @override
  void initState() {
    super.initState();

    // Checkmark draw: 500ms
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkProgress = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOut,
    );
    _colorTween = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Confetti: 1200ms
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text slide+fade: 300ms (starts after checkmark)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Buttons staggered: 300ms each, 50ms apart
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Sequence
    _checkController.forward().then((_) {
      _confettiController.forward();
      _textController.forward().then((_) {
        _buttonController.forward();
      });
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.ink.withValues(alpha: 0.6),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Checkmark circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Confetti layer
                      if (!disableAnimations)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ConfettiPainter(
                              progress: _confettiController,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Checkmark
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _checkProgress,
                          _colorTween,
                        ]),
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(120, 120),
                            painter: _CheckmarkPainter(
                              progress: _checkProgress.value,
                              colorProgress: _colorTween.value,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // "تم البيع" text + invoice details
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _textController,
                      curve: Curves.easeOutBack,
                    )),
                    child: FadeTransition(
                      opacity: _textController,
                      child: Column(
                        children: [
                          const Text(
                            'تم البيع بنجاح',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: AppSizes.fontXL,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            widget.invoiceNumber,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w500,
                              color: AppColors.background.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          // Total amount
                          Text(
                            Formatters.formatCurrency(widget.total,
                                symbol: widget.currencySymbol),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: AppSizes.fontXXL,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestLight,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (widget.change > 0) ...[
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              'الباقي: ${Formatters.formatCurrency(widget.change, symbol: widget.currencySymbol)}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: AppSizes.fontSM,
                                fontWeight: FontWeight.w600,
                                color: AppColors.background.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.xl),

                  // Action buttons (staggered)
                  FadeTransition(
                    opacity: _buttonController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _buttonController,
                        curve: Curves.easeOut,
                      )),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.onPrint != null)
                            _ActionButton(
                              icon: Icons.print_outlined,
                              label: 'طباعة',
                              onTap: widget.onPrint!,
                            ),
                          if (widget.onShare != null) ...[
                            const SizedBox(width: AppSizes.sm),
                            _ActionButton(
                              icon: Icons.share_outlined,
                              label: 'مشاركة',
                              onTap: widget.onShare!,
                            ),
                          ],
                          const SizedBox(width: AppSizes.sm),
                          _ActionButton(
                            icon: Icons.add_shopping_cart,
                            label: 'بيع جديد',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onNewSale();
                            },
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkmark painter — progressive stroke draw + color transition
class _CheckmarkPainter extends CustomPainter {
  final double progress; // 0 → 1 stroke draw
  final double colorProgress; // 0 → 1 color shift

  _CheckmarkPainter({
    required this.progress,
    required this.colorProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Background circle (stamp red outline → fills to forest green)
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Color.lerp(
        AppColors.stampRed,
        AppColors.forest,
        colorProgress,
      )!;

    // Draw circle progressively
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 4));
    final circleMetrics = circlePath.computeMetrics().first;
    canvas.drawPath(
      circleMetrics.extractPath(0, circleMetrics.length * progress),
      circlePaint,
    );

    // Checkmark path
    final checkPath = Path()
      ..moveTo(center.dx - radius * 0.35, center.dy)
      ..lineTo(center.dx - radius * 0.1, center.dy + radius * 0.25)
      ..lineTo(center.dx + radius * 0.35, center.dy - radius * 0.25);

    // Draw checkmark only after circle is ~60% done
    if (progress > 0.5) {
      final checkProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final checkPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(
          AppColors.stampRed,
          AppColors.forest,
          colorProgress,
        )!;

      final checkMetrics = checkPath.computeMetrics().first;
      canvas.drawPath(
        checkMetrics.extractPath(0, checkMetrics.length * checkProgress),
        checkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorProgress != colorProgress;
}

/// Confetti painter — 20 particles with gravity + fade
class _ConfettiPainter extends CustomPainter {
  final Animation<double> progress;

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p <= 0 || p >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42); // deterministic confetti
    const particleCount = 20;

    // Paper Ledger confetti colors
    const colors = [
      AppColors.stampRed,
      AppColors.forest,
      AppColors.ochre,
      AppColors.indigo,
      AppColors.sepia,
    ];

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final speed = 80.0 + random.nextDouble() * 60;
      final gravity = 120.0 * p * p; // accelerating fall
      final fade = 1.0 - (p * p);

      final dx = center.dx + cos(angle) * speed * p;
      final dy = center.dy + sin(angle) * speed * p + gravity;
      final opacity = (fade * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final particleSize = 6.0 + random.nextDouble() * 4;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(dx, dy),
          width: particleSize,
          height: particleSize * 0.6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress.value != progress.value;
}

/// Action button in success overlay
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(
            color: isPrimary
                ? AppColors.forestDark
                : AppColors.background.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? AppColors.background
                  : AppColors.background.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? AppColors.background
                    : AppColors.background.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}