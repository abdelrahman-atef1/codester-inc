/// payment_selector.dart — Payment method selection + amount input
///
/// T-013: نقداً / بطاقة / محفظة إلكترونية
/// Animation spec §2: chip selection with AnimatedContainer
/// Cash mode shows amount-paid input + change calculation
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/payment_method.dart';
import 'animated_total.dart';

class PaymentSelector extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final double amountPaid;
  final double total;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final ValueChanged<double> onAmountPaidChanged;
  final String currencySymbol;

  const PaymentSelector({
    super.key,
    required this.selectedMethod,
    required this.amountPaid,
    required this.total,
    required this.onMethodSelected,
    required this.onAmountPaidChanged,
    this.currencySymbol = 'ج.م',
  });

  @override
  Widget build(BuildContext context) {
    final change = selectedMethod == PaymentMethod.cash && amountPaid > 0
        ? (amountPaid >= total ? (amountPaid - total).toDouble() : 0.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label
        const Text(
          'طريقة الدفع',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // Payment method chips
        Row(
          children: PaymentMethod.values.map((method) {
            final isSelected = selectedMethod == method;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: method != PaymentMethod.values.last ? AppSizes.xs : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onMethodSelected(method);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingSM,
                      horizontal: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? method.color.withValues(alpha: 0.12)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                      border: Border.all(
                        color: isSelected
                            ? method.color
                            : AppColors.ledgerBorder,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          method.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method.label,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontXS,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? method.color
                                : AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Cash: amount paid input + change
        if (selectedMethod == PaymentMethod.cash) ...[
          const SizedBox(height: AppSizes.md),
          TextField(
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'المبلغ المدفوع',
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.inkMuted,
              ),
              suffixText: currencySymbol,
              suffixStyle: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.inkMuted,
              ),
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: AppColors.forest,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              onAmountPaidChanged(amount);
            },
          ),

          if (change > 0) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD,
                vertical: AppSizes.paddingSM,
              ),
              decoration: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                border: Border.all(
                  color: AppColors.forest.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الباقي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forest,
                    ),
                  ),
                  AnimatedTotal(
                    value: change,
                    currencySymbol: currencySymbol,
                    valueStyle: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: AppSizes.fontLG,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (amountPaid > 0 && amountPaid < total) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              'المبلغ غير كافٍ — المتبقي: ${Formatters.formatCurrency(total - amountPaid, symbol: currencySymbol)}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w500,
                color: AppColors.stampRed,
              ),
            ),
          ],
        ],
      ],
    );
  }
}