/// bold_filter_chips.dart — Horizontal scrollable category chips
///
/// Matches stitch-designs/03-inventory.html chip row:
///   * Active chip → dark slate background, white bold text
///   * Low-stock alert chip → amber tinted with pulsing dot + count
///   * Standard chips → white with border
library;

import 'package:flutter/material.dart';

import '../core/constants/bold_colors.dart';

/// Model for a filter chip
class FilterChipData {
  final String label;
  final bool isActive;
  final bool isAlert;
  final int? alertCount;

  const FilterChipData({
    required this.label,
    this.isActive = false,
    this.isAlert = false,
    this.alertCount,
  });
}

/// Horizontal scrollable chip row (RTL)
class BoldFilterChips extends StatelessWidget {
  final List<FilterChipData> chips;
  final ValueChanged<String>? onChipTap;

  const BoldFilterChips({
    super.key,
    required this.chips,
    this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: chips.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return _ChipItem(
            data: chip,
            onTap: () => onChipTap?.call(chip.label),
          );
        },
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  final FilterChipData data;
  final VoidCallback? onTap;

  const _ChipItem({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (data.isActive) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: BoldColors.dark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            data.label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (data.isAlert) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: BoldColors.amberBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BoldColors.amberBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BoldColors.amverDotWarn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BoldColors.amberText,
                ),
              ),
              if (data.alertCount != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A), // amber-200
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${data.alertCount}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF78350F), // amber-900
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Normal chip
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BoldColors.border, width: 1),
        ),
        child: Text(
          data.label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: BoldColors.textLight,
          ),
        ),
      ),
    );
  }
}
