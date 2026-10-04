/// invoice_screen.dart — فاتورة (Bold Executive receipt design from Stitch)
///
/// RTL Arabic invoice/receipt view:
/// - Dark top bar (back, invoice number + "مدفوعة" badge, more options)
/// - Teal success banner (ZATCA/ETA compliance note + time)
/// - White receipt card with sawtooth bottom edge:
///     store header (red logo stamp, name, address, phone, reg badges),
///     invoice meta grid (number / customer / date / payment method),
///     items table, subtotal/VAT/discount, dark emphasized total bar,
///     QR verification graphic + thank-you footer
/// - Support action card
/// - Fixed bottom bar: teal outlined "مشاركة" + red solid "طباعة الإيصال"
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/database.dart';
import '../data/repository.dart' show FullInvoice;
import '../providers/pos_providers.dart';
import '../services/pdf_service.dart';
import '../services/printer_service.dart';
import 'executive_theme.dart';

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, this.invoiceId});

  /// When null, shows the last invoice completed in this session
  /// ([lastInvoiceIdProvider]) or a demo invoice from the design.
  final int? invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = invoiceId ?? ref.watch(lastInvoiceIdProvider);
    final fullInvoice =
        id == null ? null : ref.watch(invoiceProvider(id)).valueOrNull;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ExecutiveColors.slate100,
        body: Column(
          children: [
            _TopBar(invoiceNumber: fullInvoice?.invoice.invoiceNumber),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _SuccessBanner(createdAt: fullInvoice?.invoice.createdAt),
                  const SizedBox(height: 16),
                  _ReceiptCard(fullInvoice: fullInvoice),
                  const SizedBox(height: 16),
                  const _SupportCard(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _ActionBar(fullInvoice: fullInvoice),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({this.invoiceNumber});

  final String? invoiceNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ExecutiveColors.slate800,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ExecutiveColors.slate700, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Back (RTL: forward arrow)
            IconButton(
              key: const Key('invoice_back_button'),
              tooltip: 'الرجوع',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_forward,
                  color: ExecutiveColors.slate200, size: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'فاتورة ${invoiceNumber ?? '#INV-00248'}',
                          style: ExecutiveText.title.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Paid badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ExecutiveColors.emerald950,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: ExecutiveColors.emerald700
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: ExecutiveColors.emerald400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'مدفوعة',
                              style: ExecutiveText.label.copyWith(
                                color: ExecutiveColors.emerald300,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'نظام نقاط البيع الإلكتروني',
                    style: ExecutiveText.label.copyWith(
                      color: ExecutiveColors.slate400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('invoice_more_button'),
              tooltip: 'المزيد من الخيارات',
              onPressed: () {},
              icon: const Icon(Icons.more_vert,
                  color: ExecutiveColors.slate300, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success banner
// ---------------------------------------------------------------------------

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({this.createdAt});

  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ExecutiveColors.teal50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ExecutiveColors.teal200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: ExecutiveColors.teal600,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم تسجيل المعاملة بنجاح',
                  style: ExecutiveText.title.copyWith(
                      color: ExecutiveColors.teal900, fontSize: 12),
                ),
                Text(
                  'معتمدة ومطابقة للمواصفات الضريبية (ZATCA / ETA)',
                  style: ExecutiveText.label.copyWith(
                      color: ExecutiveColors.teal700, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            _timeLabel(createdAt),
            style: ExecutiveText.tabular.copyWith(
                color: ExecutiveColors.teal800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime? dt) {
    if (dt == null) return '٠٤:٢٥ م';
    final hour24 = dt.hour;
    final suffix = hour24 >= 12 ? 'م' : 'ص';
    final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$h:$minute $suffix';
  }
}

// ---------------------------------------------------------------------------
// Receipt card (with sawtooth bottom edge)
// ---------------------------------------------------------------------------

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({this.fullInvoice});

  final FullInvoice? fullInvoice;

  @override
  Widget build(BuildContext context) {
    final invoice = fullInvoice?.invoice;
    final items = fullInvoice?.items ?? _demoItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              top: BorderSide(color: ExecutiveColors.border),
              left: BorderSide(color: ExecutiveColors.border),
              right: BorderSide(color: ExecutiveColors.border),
            ),
          ),
          child: Column(
            children: [
              const _StoreHeader(),
              const _PerforatedDivider(margin: 16),
              _MetaGrid(invoice: invoice),
              const _PerforatedDivider(margin: 16),
              _ItemsTable(items: items),
              const _PerforatedDivider(margin: 12),
              _TotalsBreakdown(invoice: invoice),
              _GrandTotalBar(total: invoice?.total ?? 277.85),
              const _QrFooter(),
            ],
          ),
        ),
        // Sawtooth perforation along the bottom edge
        SizedBox(
          height: 10,
          width: double.infinity,
          child: CustomPaint(
            painter: _SawtoothPainter(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Demo items matching the static Stitch design, used when there is no
/// persisted invoice yet.
final List<InvoiceItem> _demoItems = [
  // Not persisted — built via companion-like literals isn't possible for
  // read-only data classes; instead _ItemsTable falls back to static rows.
];

class _StoreHeader extends StatelessWidget {
  const _StoreHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Red logo stamp
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ExecutiveColors.red600,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'ن',
            style: ExecutiveText.headline.copyWith(
                color: Colors.white, fontSize: 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'سوبر ماركت النور',
          style: ExecutiveText.headline.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          '١٢ شارع التحرير، الدقي، الجيزة',
          style: ExecutiveText.label.copyWith(
              fontSize: 12, color: ExecutiveColors.slate500),
        ),
        const SizedBox(height: 2),
        Text(
          'هاتف: ٠١٠١٢٣٤٥٦٧٨',
          style: ExecutiveText.tabular.copyWith(
              fontSize: 12,
              color: ExecutiveColors.slate500,
              fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        // Registration badges
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: ExecutiveColors.slate100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ExecutiveColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: 'س.ت: ',
                    style: ExecutiveText.label.copyWith(
                        fontSize: 11, color: ExecutiveColors.slate500),
                  ),
                  TextSpan(
                    text: '١٠٤٥٢',
                    style: ExecutiveText.tabular.copyWith(
                        fontSize: 11, color: ExecutiveColors.slate700),
                  ),
                ]),
              ),
              Text('  |  ',
                  style: ExecutiveText.label.copyWith(
                      fontSize: 11, color: ExecutiveColors.slate300)),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: 'ب.ض: ',
                    style: ExecutiveText.label.copyWith(
                        fontSize: 11, color: ExecutiveColors.slate500),
                  ),
                  TextSpan(
                    text: '٩٨٣-٢٢١-٤٥٠',
                    style: ExecutiveText.tabular.copyWith(
                        fontSize: 11, color: ExecutiveColors.slate700),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dashed "perforation" divider (with edge notches like torn receipt paper).
class _PerforatedDivider extends StatelessWidget {
  const _PerforatedDivider({this.margin = 0});

  final double margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: margin / 2),
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: const Size(double.infinity, 2),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ExecutiveColors.slate200
      ..strokeWidth = 2;
    const dashWidth = 8.0;
    const gap = 6.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset((x + dashWidth).clamp(0, size.width), size.height / 2),
          paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SawtoothPainter extends CustomPainter {
  _SawtoothPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const tooth = 14.0;
    var x = -tooth / 2;
    while (x < size.width + tooth) {
      canvas.drawCircle(Offset(x + tooth / 2, 0), tooth / 2, paint);
      x += tooth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Meta grid: invoice number / customer / date / payment method
// ---------------------------------------------------------------------------

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({this.invoice});

  final Invoice? invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ExecutiveColors.slate100.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ExecutiveColors.slate100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Right column (RTL start)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaField(
                  label: 'رقم الفاتورة',
                  value: invoice?.invoiceNumber ?? 'INV-00248',
                  tabular: true,
                ),
                const SizedBox(height: 8),
                const _MetaField(label: 'العميل', value: 'عميل نقدي'),
              ],
            ),
          ),
          // Left column (RTL end)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaField(
                  label: 'التاريخ والوقت',
                  value: _formatDate(invoice?.createdAt),
                  tabular: true,
                  small: true,
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طريقة الدفع',
                      style: ExecutiveText.label.copyWith(
                          fontSize: 10,
                          color: ExecutiveColors.slate400,
                          fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ExecutiveColors.teal50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ExecutiveColors.teal200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments,
                              size: 13, color: ExecutiveColors.teal800),
                          const SizedBox(width: 4),
                          Text(
                            'نقداً',
                            style: ExecutiveText.label.copyWith(
                                fontSize: 11,
                                color: ExecutiveColors.teal800,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '٠٣/١٠/٢٠٢٦ - ٠٤:٢٥ م';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d/$m/$y';
  }
}

class _MetaField extends StatelessWidget {
  const _MetaField({
    required this.label,
    required this.value,
    this.tabular = false,
    this.small = false,
  });

  final String label;
  final String value;
  final bool tabular;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ExecutiveText.label.copyWith(
              fontSize: 10,
              color: ExecutiveColors.slate400,
              fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: (tabular ? ExecutiveText.tabular : ExecutiveText.title)
              .copyWith(fontSize: small ? 11 : 12),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Items table
// ---------------------------------------------------------------------------

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items});

  final List<InvoiceItem> items;

  /// Static rows straight from the Stitch design (shown when no DB invoice).
  static const _rows = <(String, String, int, double)>[
    ('حليب جهينة ١ لتر', 'كامل الدسم', 2, 35.00),
    ('أرز الضحى ١ كجم', 'فاخر مصري', 3, 32.50),
    ('شاي العروسة ٢٥٠ جم', 'أسود ناعم', 1, 45.00),
    ('بيبسي ٣٣٠ مل', 'علبة كانز', 4, 10.00),
  ];

  @override
  Widget build(BuildContext context) {
    final useDb = items.isNotEmpty;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: ExecutiveColors.slate100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('الصنف',
                    textAlign: TextAlign.start,
                    style: _headerStyle),
              ),
              SizedBox(
                width: 48,
                child:
                    Text('الكمية', textAlign: TextAlign.center, style: _headerStyle),
              ),
              SizedBox(
                width: 64,
                child:
                    Text('السعر', textAlign: TextAlign.end, style: _headerStyle),
              ),
              SizedBox(
                width: 80,
                child: Text('الإجمالي',
                    textAlign: TextAlign.end, style: _headerStyle),
              ),
            ],
          ),
        ),
        // Rows
        if (useDb)
          for (final item in items)
            _ItemRow(
              title: item.name,
              subtitle: item.subtitle ?? '',
              quantity: item.quantity,
              price: item.price,
              total: item.total,
            )
        else
          for (final row in _rows)
            _ItemRow(
              title: row.$1,
              subtitle: row.$2,
              quantity: row.$3,
              price: row.$4,
              total: row.$3 * row.$4,
            ),
      ],
    );
  }

  TextStyle get _headerStyle => ExecutiveText.label.copyWith(
      fontSize: 11, color: ExecutiveColors.slate500, fontWeight: FontWeight.w700);
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.price,
    required this.total,
  });

  final String title;
  final String subtitle;
  final int quantity;
  final double price;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('invoice_item_$title'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ExecutiveColors.slate100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ExecutiveText.title.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: ExecutiveText.label.copyWith(
                          fontSize: 10, color: ExecutiveColors.slate400)),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: ExecutiveText.tabular.copyWith(
                    fontSize: 12, color: ExecutiveColors.slate700)),
          ),
          SizedBox(
            width: 64,
            child: Text(price.toStringAsFixed(2),
                textAlign: TextAlign.end,
                style: ExecutiveText.tabular.copyWith(
                    fontSize: 12,
                    color: ExecutiveColors.slate600,
                    fontWeight: FontWeight.w400)),
          ),
          SizedBox(
            width: 80,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: total.toStringAsFixed(2),
                  style: ExecutiveText.tabular.copyWith(fontSize: 12),
                ),
                TextSpan(
                  text: ' ج.م',
                  style: ExecutiveText.label.copyWith(
                      fontSize: 10, color: ExecutiveColors.slate500),
                ),
              ]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals breakdown + emphasized total bar
// ---------------------------------------------------------------------------

class _TotalsBreakdown extends StatelessWidget {
  const _TotalsBreakdown({this.invoice});

  final Invoice? invoice;

  @override
  Widget build(BuildContext context) {
    final subtotal = invoice?.subtotal ?? 252.50;
    final tax = invoice?.tax ?? 35.35;
    final discount = invoice?.discount ?? 10.00;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _TotalRow(
            label: 'المجموع الفرعي',
            value: '${subtotal.toStringAsFixed(2)} ج.م',
          ),
          const SizedBox(height: 8),
          _TotalRow(
            label: 'ضريبة القيمة المضافة (١٤٪)',
            value: '${tax.toStringAsFixed(2)} ج.م',
          ),
          const SizedBox(height: 8),
          // Discount row in red
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sell,
                      size: 14, color: ExecutiveColors.red600),
                  const SizedBox(width: 4),
                  Text(
                    'خصم ترويجي',
                    style: ExecutiveText.label.copyWith(
                        fontSize: 12,
                        color: ExecutiveColors.red600,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                '−${discount.toStringAsFixed(2)} ج.م',
                style: ExecutiveText.tabular.copyWith(
                    fontSize: 12, color: ExecutiveColors.red600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ExecutiveText.label.copyWith(
              fontSize: 12, color: ExecutiveColors.slate600),
        ),
        Text(
          value,
          style: ExecutiveText.tabular.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _GrandTotalBar extends StatelessWidget {
  const _GrandTotalBar({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('grand_total_bar'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ExecutiveColors.slate800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإجمالي النهائي',
                style: ExecutiveText.label.copyWith(
                    fontSize: 11,
                    color: ExecutiveColors.slate400,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                'شامل ضريبة القيمة المضافة',
                style: ExecutiveText.label.copyWith(
                    fontSize: 10,
                    color: ExecutiveColors.emerald400),
              ),
            ],
          ),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: total.toStringAsFixed(2),
                style: ExecutiveText.headline.copyWith(
                    color: Colors.white, fontSize: 24, letterSpacing: -0.5),
              ),
              TextSpan(
                text: ' ج.م',
                style: ExecutiveText.title.copyWith(
                    fontSize: 12, color: ExecutiveColors.slate300),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QR footer
// ---------------------------------------------------------------------------

class _QrFooter extends StatelessWidget {
  const _QrFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ExecutiveColors.slate800, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
            child: QrImageView(
              key: const Key('invoice_qr'),
              data: 'FA-98322-ET | INV-00248 | 277.85 EGP',
              version: QrVersions.auto,
              size: 112,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ExecutiveColors.slate900,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: ExecutiveColors.slate900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'شكراً لتعاملكم معنا',
            style: ExecutiveText.title.copyWith(fontSize: 14),
          ),
          Text(
            'فاتورة ضريبية مبسطة رقم 00248',
            style: ExecutiveText.tabular.copyWith(
                fontSize: 11,
                color: ExecutiveColors.slate400,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text(
            'رمز التحقق الإلكتروني: FA-98322-ET',
            style: ExecutiveText.label.copyWith(
                fontSize: 10, color: ExecutiveColors.slate400),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Support card
// ---------------------------------------------------------------------------

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ExecutiveColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent,
              color: ExecutiveColors.slate500, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'هل تواجه مشكلة بالفاتورة؟',
              style: ExecutiveText.label.copyWith(
                  fontSize: 12,
                  color: ExecutiveColors.slate700,
                  fontWeight: FontWeight.w500),
            ),
          ),
          InkWell(
            onTap: () {},
            child: Text(
              'الإبلاغ عن خطأ',
              style: ExecutiveText.body.copyWith(
                  fontSize: 12, color: ExecutiveColors.red600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar: share + print
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({this.fullInvoice});

  final FullInvoice? fullInvoice;

  Future<void> _onPrint(BuildContext context) async {
    final invoice = fullInvoice;
    if (invoice == null) {
      _toast(context, 'لا توجد فاتورة للطباعة');
      return;
    }
    // Try Bluetooth thermal printer first; fall back to system PDF print.
    final result = await PrinterService().printReceipt(invoice);
    if (!context.mounted) return;
    if (result.ok) {
      _toast(context, result.message);
      return;
    }
    // Bluetooth unavailable/failed → system print dialog with PDF body.
    final pdfBytes = await PdfService().generateInvoicePdf(invoice);
    await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(pdfBytes));
  }

  Future<void> _onShare(BuildContext context) async {
    final invoice = fullInvoice;
    if (invoice == null) {
      _toast(context, 'لا توجد فاتورة للمشاركة');
      return;
    }
    final result = await PdfService().shareInvoicePdf(invoice);
    if (!context.mounted) return;
    if (!result.ok) _toast(context, result.message);
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ExecutiveColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Outlined teal share
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('share_button'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: ExecutiveColors.teal600, width: 2),
                  foregroundColor: ExecutiveColors.teal700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onPressed: () => _onShare(context),
                icon: const Icon(Icons.share, size: 20),
                label: Text('مشاركة',
                    style: ExecutiveText.title.copyWith(
                        fontSize: 14, color: ExecutiveColors.teal700)),
              ),
            ),
            const SizedBox(width: 12),
            // Solid red print
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('print_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ExecutiveColors.red600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                  ),
                  onPressed: () => _onPrint(context),
                  icon: const Icon(Icons.print, size: 20),
                  label: Text('طباعة الإيصال',
                      style: ExecutiveText.headline.copyWith(
                          fontSize: 14, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
