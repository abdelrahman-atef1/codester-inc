/// cart_item_card.dart — Single cart line item in POS cart
///
/// Features:
/// - Slide-in + fade on appearance (animation spec §4a)
/// - Dismissible swipe-to-delete (animation spec §4c)
/// - Quantity stepper with AnimatedSwitcher number flip
/// - RepaintBoundary for repaint isolation
/// - Paper Ledger design: bordered card, no shadow
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/cart_item.dart';

class CartItemCard extends StatefulWidget {
  final CartItem cartItem;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final String currencySymbol;

  const CartItemCard({
    super.key,
    required this.cartItem,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.currencySymbol = 'ج.م',
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Slide-in: from right +12px → 0, 300ms, easeOutBack
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.cartItem;

    return RepaintBoundary(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: ValueKey(item.product.id),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              HapticFeedback.mediumImpact();
              widget.onRemove();
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSizes.paddingLG),
              decoration: BoxDecoration(
                color: AppColors.stampRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.stampRed, width: 1.5),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.stampRed,
                size: AppSizes.iconLG,
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: AppSizes.paddingLG),
              decoration: BoxDecoration(
                color: AppColors.stampRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.stampRed, width: 1.5),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.stampRed,
                size: AppSizes.iconLG,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSM,
                vertical: AppSizes.paddingSM,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  // Product name + unit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Formatters.formatCurrency(item.product.price, symbol: widget.currencySymbol)} × ${item.product.unit}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontXS,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity stepper
                  _QuantityStepper(
                    quantity: item.quantity,
                    onIncrement: widget.onIncrement,
                    onDecrement: widget.onDecrement,
                  ),

                  const SizedBox(width: AppSizes.sm),

                  // Line total
                  SizedBox(
                    width: 80,
                    child: Text(
                      Formatters.formatCurrency(item.lineTotal,
                          symbol: widget.currencySymbol),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                        fontFeatures: [FontFeature.tabularFigures()],
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

/// Quantity stepper with AnimatedSwitcher number flip
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus
        _StepButton(
          icon: Icons.remove,
          onTap: () {
            HapticFeedback.lightImpact();
            onDecrement();
          },
        ),
        const SizedBox(width: 4),
        // Number with flip animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: 28,
            key: ValueKey(quantity),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Plus
        _StepButton(
          icon: Icons.add,
          onTap: () {
            HapticFeedback.lightImpact();
            onIncrement();
          },
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            border: Border.all(color: AppColors.ledgerBorder, width: 1),
          ),
          child: Icon(icon, size: 16, color: AppColors.ink),
        ),
      ),
    );
  }
}