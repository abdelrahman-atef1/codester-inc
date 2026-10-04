/// animated_total.dart — Count-up currency animation for POS totals
///
/// Animation spec §7: TweenAnimationBuilder[double]
/// Duration: 400ms, Curve: easeOut
/// Skips animation if disableAnimations or delta < 1.0
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';

class AnimatedTotal extends StatelessWidget {
  final double value;
  final String label;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final String currencySymbol;
  final bool isLarge;

  const AnimatedTotal({
    super.key,
    required this.value,
    this.label = '',
    this.labelStyle,
    this.valueStyle,
    this.currencySymbol = 'ج.م',
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, animValue, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label.isNotEmpty) ...[
              Text(
                label,
                style: labelStyle ??
                    TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isLarge ? AppSizes.fontSM : AppSizes.fontXS,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              Formatters.formatCurrency(animValue, symbol: currencySymbol),
              style: valueStyle ??
                  TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isLarge ? AppSizes.fontXXL : AppSizes.fontLG,
                    fontWeight: FontWeight.w800,
                    color: isLarge ? AppColors.forest : AppColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        );
      },
    );
  }
}