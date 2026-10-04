/// bold_bottom_nav.dart — Bottom navigation matching stitch-designs shared nav
///
/// 4 items: نقطة البيع, الفواتير, المخزون, التقارير
/// Active item: red icon + bold label, small red indicator line above icon.
/// Inactive: slate-500 icon + semibold label.
library;

import 'package:flutter/material.dart';

import '../core/constants/bold_colors.dart';

/// Nav item model
class BoldNavItem {
  final IconData icon;
  final String label;
  final bool isActive;

  const BoldNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });
}

/// Bottom navigation bar (RTL)
class BoldBottomNav extends StatelessWidget {
  final List<BoldNavItem> items;
  final ValueChanged<int>? onTap;

  const BoldBottomNav({
    super.key,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: BoldColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                item: items[i],
                onTap: () => onTap?.call(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BoldNavItem item;
  final VoidCallback? onTap;

  const _NavItem({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Active indicator line
              if (item.isActive)
                Container(
                  width: 32,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: BoldColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Icon(
                item.icon,
                size: 22,
                color: item.isActive
                    ? BoldColors.primary
                    : BoldColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight:
                      item.isActive ? FontWeight.w700 : FontWeight.w600,
                  color: item.isActive
                      ? BoldColors.primary
                      : BoldColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
