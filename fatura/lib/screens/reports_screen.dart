/// reports_screen.dart — Bold Executive Reports Screen
///
/// Replicates stitch-designs/04-reports.html:
///   Dark slate app bar "فاتورة" with share/print, segment control (اليوم/الأسبوع/الشهر),
///   dark hero KPI card (مبيعات اليوم), secondary KPI grid, hourly bar chart
///   (fl_chart), top-5 products with progress bars, bottom nav.
///
/// Colors: #E63946 (red), #2A9D8F (teal), #F1F5F9 (bg), #1E293B (dark)
/// Font: Cairo (bold weights for headers)
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/bold_colors.dart';
import '../../widgets/bold_bottom_nav.dart';

/// Converts Latin digits in [input] to Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩),
/// keeping the decimal mark and thousands separator as in the HTML design
/// (٫ decimal, , thousands).
String toArabicDigits(String input) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var result = input;
  for (var i = 0; i < western.length; i++) {
    result = result.replaceAll(western[i], arabic[i]);
  }
  return result.replaceAll('.', '٫');
}

/// Formats a price with thousands separator (Latin comma as in HTML design)
/// and Arabic-Indic digits.
String formatArabicMoney(num value) {
  final intValue = value.round();
  final str = intValue.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return toArabicDigits(buffer.toString());
}

/// Top-selling product model
class TopProduct {
  final String name;
  final int quantitySold;
  final double revenue;
  final double progressPercent;

  const TopProduct({
    required this.name,
    required this.quantitySold,
    required this.revenue,
    required this.progressPercent,
  });
}

/// Hourly sales point
class HourlySales {
  final String label; // e.g. "٩ ص"
  final double percent; // 0.0 - 1.0 bar fill
  final bool isPeak;
  final String? peakAmount;

  const HourlySales({
    required this.label,
    required this.percent,
    this.isPeak = false,
    this.peakAmount,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriod = 0; // 0=اليوم, 1=الأسبوع, 2=الشهر

  // Sample chart data matching HTML design
  final List<HourlySales> _hourlySales = const [
    HourlySales(label: '٩ ص', percent: 0.32),
    HourlySales(label: '١١ ص', percent: 0.48),
    HourlySales(label: '١ م', percent: 0.62),
    HourlySales(label: '٣ م', percent: 0.44),
    HourlySales(label: '٥ م', percent: 0.92, isPeak: true, peakAmount: '٣,٢٤٠'),
    HourlySales(label: '٧ م', percent: 0.72),
    HourlySales(label: '٩ م', percent: 0.38),
  ];

  // Sample top products matching HTML design
  final List<TopProduct> _topProducts = const [
    TopProduct(name: 'أرز الضحى ١ كجم', quantitySold: 64, revenue: 2080.0, progressPercent: 0.85),
    TopProduct(name: 'حليب جهينة ١ لتر', quantitySold: 58, revenue: 2030.0, progressPercent: 0.80),
    TopProduct(name: 'بيبسي ٣٣٠ مل', quantitySold: 112, revenue: 1120.0, progressPercent: 0.55),
    TopProduct(name: 'شاي العروسة ٢٥٠ جم', quantitySold: 21, revenue: 945.0, progressPercent: 0.42),
    TopProduct(name: 'زيت كريستال ذرة ٨٠٠ مل', quantitySold: 12, revenue: 840.0, progressPercent: 0.35),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BoldColors.bg,
        bottomNavigationBar: _buildBottomNav(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── Dark App Bar ───
              _buildAppBar(),
              // ─── Scrollable Content ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),
                        _buildTitleSection(),
                        const SizedBox(height: 12),
                        _buildSegmentControl(),
                        const SizedBox(height: 14),
                        _buildHeroCard(),
                        const SizedBox(height: 12),
                        _buildKpiGrid(),
                        const SizedBox(height: 12),
                        _buildHourlyChartCard(),
                        const SizedBox(height: 12),
                        _buildTopProductsCard(),
                        const SizedBox(height: 12),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── App Bar ───

  Widget _buildAppBar() {
    return Container(
      height: 56,
      color: BoldColors.dark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.storefront, color: BoldColors.primary, size: 22),
            const SizedBox(width: 10),
            const Text(
              'فاتورة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Share button
            _appBarIcon(Icons.share, () {
              // TODO: Share report
            }),
            const SizedBox(width: 6),
            // Print button
            _appBarIcon(Icons.print, () {
              // TODO: Print report
            }),
          ],
        ),
      ),
    );
  }

  Widget _appBarIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ),
        child: Icon(icon, color: BoldColors.textFaint, size: 22),
      ),
    );
  }

  // ─── Title + Date chip ───

  Widget _buildTitleSection() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التقارير',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: BoldColors.text,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'ملخص الأداء والمبيعات اللحظية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: BoldColors.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BoldColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 14, color: BoldColors.accent),
              SizedBox(width: 6),
              Text(
                '٢٤ أكتوبر ٢٠٢٣',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BoldColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Segment Control (اليوم/الأسبوع/الشهر) ───

  Widget _buildSegmentControl() {
    final labels = ['اليوم', 'الأسبوع', 'الشهر'];
    return Container(
      height: 36,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BoldColors.border.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = _selectedPeriod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isActive ? BoldColors.heroCardDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isActive
                      ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? Colors.white : BoldColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Hero KPI Card (Dark) ───

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BoldColors.heroCardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BoldColors.heroCardLine),
      ),
      child: Column(
        children: [
          // Top row: label + trend badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مبيعات اليوم الإجمالية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BoldColors.textFaint,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '١٢,٤٨٥٫٠٠',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ج.م',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BoldColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BoldColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BoldColors.accent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: BoldColors.accent, size: 12),
                    SizedBox(width: 4),
                    Text(
                      '▲ ١٨٪',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BoldColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom row: two secondary stats
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: BoldColors.heroCardLine, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _heroSecondaryStat(
                    'صافي الأرباح',
                    '٣,١٢٠',
                    'ج.م',
                    BoldColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _heroSecondaryStat(
                    'ضريبة القيمة المضافة (١٤٪)',
                    '١,٥٣٢',
                    'ج.م',
                    Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSecondaryStat(String label, String value, String unit, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BoldColors.heroCardLine.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: BoldColors.textFaint,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: BoldColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Secondary KPI Grid (2-col) ───

  Widget _buildKpiGrid() {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            label: 'عدد الفواتير',
            value: '٤٧',
            unit: 'فاتورة',
            icon: Icons.receipt_long,
            iconColor: BoldColors.primary,
            iconBg: BoldColors.redBg,
            delta: '↑ +٥ مقارنة بأمس',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            label: 'متوسط الفاتورة',
            value: '٢٦٥٫٦٤',
            unit: 'ج.م',
            icon: Icons.analytics,
            iconColor: BoldColors.accent,
            iconBg: BoldColors.tealBg,
            delta: '↑ +١٢ ج.م عن أمس',
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String delta,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BoldColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BoldColors.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BoldColors.text,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BoldColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_upward, size: 13, color: BoldColors.accent),
              const SizedBox(width: 2),
              Text(
                delta,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: BoldColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Hourly Chart Card ───

  Widget _buildHourlyChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BoldColors.border),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المبيعات بالساعة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BoldColors.text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ذروة المبيعات: ٥:٠٠ م - ٦:٠٠ م',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: BoldColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: BoldColors.chipGrey,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: BoldColors.border),
                ),
                child: const Text(
                  'توقيت محلي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BoldColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chart area
          SizedBox(
            height: 160,
            child: _buildHourlyBars(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHourlyBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _hourlySales.map((hour) {
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Peak callout badge
              if (hour.isPeak && hour.peakAmount != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: BoldColors.heroCardDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hour.peakAmount!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        ' ج.م',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 7,
                          color: BoldColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 18),
              // Bar
              SizedBox(
                height: 110,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 16,
                    height: 110 * hour.percent,
                    decoration: BoxDecoration(
                      color: hour.isPeak
                          ? BoldColors.primary
                          : BoldColors.borderStrong,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                      boxShadow: hour.isPeak
                          ? const [
                              BoxShadow(
                                color: Color(0x1AE63946),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              // Label
              const SizedBox(height: 6),
              Text(
                hour.label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: hour.isPeak ? FontWeight.w800 : FontWeight.w700,
                  color: hour.isPeak ? BoldColors.primary : BoldColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Top Products Card ───

  Widget _buildTopProductsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BoldColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأكثر مبيعاً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BoldColors.text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'حسب الإيراد المحقق اليوم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: BoldColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BoldColors.tealBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BoldColors.tealBorder),
                ),
                child: const Text(
                  'أفضل ٥ أصناف',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: BoldColors.tealText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Product items
          for (var i = 0; i < _topProducts.length; i++) ...[
            _buildTopProductItem(
              rank: i + 1,
              product: _topProducts[i],
              isLast: i == _topProducts.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopProductItem({
    required int rank,
    required TopProduct product,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: 10,
        bottom: isLast ? 0 : 10,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: BoldColors.chipGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    toArabicDigits('$rank'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: BoldColors.textLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Product name + units
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BoldColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${toArabicDigits('${product.quantitySold}')} وحدة مباعة',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: BoldColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Revenue
              Text(
                formatArabicMoney(product.revenue),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: BoldColors.text,
                ),
              ),
              const Text(
                'ج.م',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: BoldColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Teal progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: BoldColors.chipGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: product.progressPercent,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: BoldColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: BoldColors.border),
          ],
        ],
      ),
    );
  }

  // ─── Footer ───

  Widget _buildFooter() {
    return const Text(
      'فاتورة POS • متوافق مع متطلبات الفاتورة الإلكترونية المصرية',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: BoldColors.textFaint,
      ),
    );
  }

  // ─── Bottom Nav ───

  Widget _buildBottomNav() {
    return BoldBottomNav(
      items: const [
        BoldNavItem(icon: Icons.point_of_sale, label: 'نقطة البيع'),
        BoldNavItem(icon: Icons.receipt_long, label: 'الفواتير'),
        BoldNavItem(icon: Icons.inventory_2, label: 'المخزون'),
        BoldNavItem(icon: Icons.bar_chart, label: 'التقارير', isActive: true),
      ],
      onTap: (index) {
        // TODO: Navigate to other screens
      },
    );
  }
}
