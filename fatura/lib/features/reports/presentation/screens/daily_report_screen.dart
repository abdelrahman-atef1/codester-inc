/// daily_report_screen.dart — T-016: Daily Report Screen
///
/// Paper Ledger style: cream paper, bordered cards, fl_chart bar chart,
/// summary stats, top 5 products, PDF export button.
/// RTL Arabic-first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/report_providers.dart';
import '../widgets/pdf_export.dart';

class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(dailyReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.dailyReport),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.stampRed),
            tooltip: AppStrings.exportPdf,
            onPressed: () async {
              final report = ref.read(dailyReportProvider).valueOrNull;
              if (report != null) {
                await exportDailyReportPdf(context, report);
              }
            },
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => _ReportContent(report: report),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.forest, strokeWidth: 2),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.stampRed),
              const SizedBox(height: AppSizes.sm),
              Text(
                'تعذر تحميل التقرير: $err',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontSM,
                  color: AppColors.inkLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.md),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(dailyReportProvider),
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

// ─── Report Content ───

class _ReportContent extends StatelessWidget {
  final DailyReport report;

  const _ReportContent({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DateHeader(date: report.date),
          const SizedBox(height: AppSizes.md),
          _SummaryStats(report: report),
          const SizedBox(height: AppSizes.md),
          _SalesChartCard(chartData: report.chartData),
          const SizedBox(height: AppSizes.md),
          _TopProductsCard(topProducts: report.topProducts),
          const SizedBox(height: AppSizes.md),
          _ExportButton(report: report),
        ],
      ),
    );
  }
}

// ─── Date Header ───

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forest,
              border: Border.all(color: AppColors.forestDark, width: 1.5),
            ),
            child: const Icon(Icons.calendar_today, color: AppColors.background, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تقرير مبيعات يوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    color: AppColors.inkMuted,
                  ),
                ),
                Text(
                  Formatters.formatDate(date),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Stats ───

class _SummaryStats extends StatelessWidget {
  final DailyReport report;

  const _SummaryStats({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: AppStrings.totalSales,
            value: Formatters.formatCurrency(report.totalSales),
            icon: Icons.payments,
            color: AppColors.forest,
            bgColor: const Color(0x1A2D6A4F),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: AppStrings.invoiceCount,
            value: '${report.invoiceCount}',
            icon: Icons.receipt_long,
            color: AppColors.indigo,
            bgColor: const Color(0x1A3D5A80),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'متوسط الفاتورة',
            value: Formatters.formatCurrency(report.averageInvoice),
            icon: Icons.trending_up,
            color: AppColors.ochre,
            bgColor: const Color(0x1AB8860B),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: AppColors.inkMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Sales Chart Card ───

class _SalesChartCard extends StatelessWidget {
  final List<DailySalesPoint> chartData;

  const _SalesChartCard({required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المبيعات بالساعة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          if (chartData.isEmpty)
            const _EmptyChart()
          else
            _BarChart(chartData: chartData),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: const Text(
        'لا توجد مبيعات اليوم',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontSM,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<DailySalesPoint> chartData;

  const _BarChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final maxY = chartData.fold<double>(
        0.0, (max, p) => p.sales > max ? p.sales : max);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.15,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, gIdx, rod, rIdx) {
                final point = chartData[gIdx];
                return BarTooltipItem(
                  '${point.hour}:00\n${Formatters.formatCurrency(point.sales)}',
                  const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.background,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= chartData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${chartData[idx].hour}س',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(chartData.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: chartData[i].sales,
                  color: AppColors.forest,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.15,
                    color: const Color(0x0D2C2C2C),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── Top Products Card ───

class _TopProductsCard extends StatelessWidget {
  final List<TopProduct> topProducts;

  const _TopProductsCard({required this.topProducts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.topProducts,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'لا توجد منتجات مبيعة اليوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: AppSizes.fontSM,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            )
          else
            ...topProducts.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final product = entry.value;
              return _TopProductRow(rank: rank, product: product);
            }),
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final int rank;
  final TopProduct product;

  const _TopProductRow({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? AppColors.ochre
        : rank == 2
            ? AppColors.sepia
            : AppColors.inkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(rankColor.r.round(), rankColor.g.round(), rankColor.b.round(), 0.15),
              border: Border.all(color: rankColor, width: 1.2),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${product.quantitySold} قطعة',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontXS,
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.formatCurrency(product.revenue),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Export Button ───

class _ExportButton extends StatelessWidget {
  final DailyReport report;

  const _ExportButton({required this.report});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => exportDailyReportPdf(context, report),
      icon: const Icon(Icons.picture_as_pdf, size: 20),
      label: const Text(AppStrings.exportPdf),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.stampRed,
        side: const BorderSide(color: AppColors.stampRed, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
      ),
    );
  }
}