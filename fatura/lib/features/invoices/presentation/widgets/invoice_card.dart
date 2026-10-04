/// invoice_card.dart — Invoice card for list view
///
/// Paper Ledger style: bordered card, cream surface, no shadow.
/// Shows invoice number, date, total, status badge, payment method icon.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart' as db;
import '../../../../core/utils/formatters.dart';
import '../widgets/status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final db.Invoice invoice;
  final VoidCallback? onTap;

  const InvoiceCard({super.key, required this.invoice, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment method icon (left in RTL = right side visually)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _paymentBg(invoice.paymentMethod),
                borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                border: Border.all(
                    color: _paymentBorder(invoice.paymentMethod), width: 1),
              ),
              child: Icon(
                _paymentIcon(invoice.paymentMethod),
                size: 22,
                color: _paymentColor(invoice.paymentMethod),
              ),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice number + status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      StatusBadge(status: invoice.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Date + customer
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatDateTime(invoice.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontXS,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      if (invoice.customerName != null &&
                          invoice.customerName!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Text('·',
                            style: TextStyle(color: AppColors.inkMuted)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            invoice.customerName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: AppSizes.fontXS,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _paymentLabel(invoice.paymentMethod),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontXS,
                          color: AppColors.inkLight,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(invoice.total),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontLG,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Chevron
            const Icon(
              Icons.chevron_left,
              color: AppColors.inkMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _paymentIcon(String? method) {
    switch (method) {
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _paymentColor(String? method) {
    switch (method) {
      case 'cash':
        return AppColors.forest;
      case 'card':
        return AppColors.indigo;
      case 'wallet':
        return AppColors.sepia;
      default:
        return AppColors.inkMuted;
    }
  }

  Color _paymentBg(String? method) {
    switch (method) {
      case 'cash':
        return const Color(0x1A2D6A4F);
      case 'card':
        return const Color(0x1A3D5A80);
      case 'wallet':
        return const Color(0x1A7B5E3B);
      default:
        return const Color(0x1A8A8270);
    }
  }

  Color _paymentBorder(String? method) {
    switch (method) {
      case 'cash':
        return AppColors.forestLight;
      case 'card':
        return AppColors.indigo;
      case 'wallet':
        return AppColors.sepia;
      default:
        return AppColors.ledgerBorder;
    }
  }

  String _paymentLabel(String? method) {
    switch (method) {
      case 'cash':
        return AppStrings.cash;
      case 'card':
        return AppStrings.card;
      case 'wallet':
        return AppStrings.wallet;
      default:
        return '-';
    }
  }
}