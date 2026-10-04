/// invoice_detail_screen.dart — T-015: Invoice Detail Screen
///
/// Paper Ledger style: full invoice view with store info, items, totals,
/// payment info, share + delete buttons.
/// RTL Arabic-first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart' as db;
import '../../../../core/utils/formatters.dart';
import '../../providers/invoice_providers.dart';
import '../widgets/status_badge.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(invoiceDetailProvider(invoiceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل الفاتورة'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        data: (detail) => _DetailContent(detail: detail),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.forest,
            strokeWidth: 2,
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.stampRed),
              const SizedBox(height: AppSizes.sm),
              Text(
                'تعذر تحميل الفاتورة',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontLG,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(invoiceDetailProvider(invoiceId)),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail Content ───

class _DetailContent extends ConsumerWidget {
  final InvoiceDetail detail;

  const _DetailContent({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = detail.invoice;
    final store = detail.store;
    final seller = detail.seller;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Store Info Card ───
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              store?.name ?? AppStrings.appName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: AppSizes.fontXL,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          StatusBadge(status: inv.status),
                        ],
                      ),
                      if (store?.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          store!.address!,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontXS,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const _DashedDivider(),
                      const SizedBox(height: 12),
                      // Invoice number + date
                      _InfoRow(
                        label: AppStrings.invoiceNumber,
                        value: inv.invoiceNumber,
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: AppStrings.invoiceDate,
                        value: Formatters.formatDateTime(inv.createdAt),
                      ),
                      if (seller != null) ...[
                        const SizedBox(height: 6),
                        _InfoRow(
                          label: 'البائع',
                          value: seller.name,
                        ),
                      ],
                      if (inv.customerName != null &&
                          inv.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _InfoRow(
                          label: AppStrings.customerName,
                          value: inv.customerName!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // ─── Items List ───
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الأصناف',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontLG,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Items header
                      _ItemsHeader(),
                      const SizedBox(height: 4),
                      ...detail.items.map((item) => _ItemRow(item: item)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // ─── Totals Card ───
                _SectionCard(
                  child: Column(
                    children: [
                      _TotalRow(
                        label: AppStrings.subtotal,
                        value: Formatters.formatCurrency(inv.subtotal),
                      ),
                      if (inv.tax > 0) ...[
                        const SizedBox(height: 8),
                        _TotalRow(
                          label: AppStrings.tax,
                          value: Formatters.formatCurrency(inv.tax),
                        ),
                      ],
                      if (inv.discount > 0) ...[
                        const SizedBox(height: 8),
                        _TotalRow(
                          label: AppStrings.discount,
                          value: '- ${Formatters.formatCurrency(inv.discount)}',
                          valueColor: AppColors.stampRed,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const _DashedDivider(),
                      const SizedBox(height: 12),
                      _TotalRow(
                        label: AppStrings.total,
                        value: Formatters.formatCurrency(inv.total),
                        isGrandTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // ─── Payment Info ───
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.paymentMethod,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _paymentIcon(inv.paymentMethod),
                            size: 20,
                            color: _paymentColor(inv.paymentMethod),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _paymentLabel(inv.paymentMethod),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: AppSizes.fontMD,
                              fontWeight: FontWeight.w600,
                              color: _paymentColor(inv.paymentMethod),
                            ),
                          ),
                          const Spacer(),
                          if (inv.amountPaid != null)
                            Text(
                              '${AppStrings.amountPaid}: ${Formatters.formatCurrency(inv.amountPaid!)}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: AppSizes.fontSM,
                                color: AppColors.inkLight,
                              ),
                            ),
                        ],
                      ),
                      if (inv.change != null && inv.change! > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.change}: ${Formatters.formatCurrency(inv.change!)}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontSM,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── Bottom Action Buttons ───
        _BottomActions(invoiceId: inv.id, invoice: inv),
      ],
    );
  }
}

// ─── Bottom Actions (Share + Delete) ───

class _BottomActions extends ConsumerWidget {
  final int invoiceId;
  final db.Invoice invoice;

  const _BottomActions({required this.invoiceId, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Share button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareInvoice(context, invoice),
              icon: const Icon(Icons.share, size: 20),
              label: const Text(AppStrings.share),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forest,
                side: const BorderSide(color: AppColors.forest, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Delete button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text(AppStrings.delete),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.stampRed,
                side: const BorderSide(color: AppColors.stampRed, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareInvoice(BuildContext context, db.Invoice inv) {
    final text = StringBuffer()
      ..writeln('═══════════════')
      ..writeln('فاتورة #${inv.invoiceNumber}')
      ..writeln('التاريخ: ${Formatters.formatDateTime(inv.createdAt)}')
      ..writeln('───────────────')
      ..writeln('الإجمالي: ${Formatters.formatCurrency(inv.total)}')
      ..writeln('طريقة الدفع: ${_paymentLabel(inv.paymentMethod)}')
      ..writeln('═══════════════')
      ..writeln('مرسلة من تطبيق فاتورة');

    Share.share(text.toString(), subject: 'فاتورة ${inv.invoiceNumber}');
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        title: const Text(
          'حذف الفاتورة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الفاتورة؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.inkLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(deleteInvoiceProvider(invoiceId).future);
              if (context.mounted) {
                context.pop();
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.stampRed,
              side: const BorderSide(color: AppColors.stampRed),
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: child,
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = AppColors.ledgerLine
      ..strokeWidth = 1.2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontSM,
            color: AppColors.inkMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.ledgerLine, width: 1),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 3,
            child: Text(
              'الصنف',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'كمية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'سعر',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'إجمالي',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final db.InvoiceItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                color: AppColors.inkLight,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.formatCurrency(item.price),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                color: AppColors.inkLight,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.formatCurrency(item.total),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGrandTotal;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isGrandTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isGrandTotal ? AppSizes.fontLG : AppSizes.fontMD,
            fontWeight: isGrandTotal ? FontWeight.w700 : FontWeight.w500,
            color: isGrandTotal ? AppColors.ink : AppColors.inkLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isGrandTotal ? AppSizes.fontXL : AppSizes.fontMD,
            fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ??
                (isGrandTotal ? AppColors.forest : AppColors.ink),
          ),
        ),
      ],
    );
  }
}

// ─── Payment Helpers ───

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