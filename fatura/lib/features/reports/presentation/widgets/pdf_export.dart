/// pdf_export.dart — PDF export utility for daily report
///
/// Generates a Paper Ledger styled PDF using the `pdf` + `printing` packages.
/// Shares via `share_plus` or opens system print dialog.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/report_providers.dart';

/// Export daily report as PDF — share via system dialog
Future<void> exportDailyReportPdf(BuildContext context, DailyReport report) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ─── Header ───
                pw.Center(
                  child: pw.Text(
                    AppStrings.appName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    AppStrings.dailyReport,
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    Formatters.formatDate(report.date),
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 16),

                // ─── Summary Stats ───
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfStat(AppStrings.totalSales,
                        Formatters.formatCurrency(report.totalSales)),
                    _pdfStat(AppStrings.invoiceCount,
                        '${report.invoiceCount}'),
                    _pdfStat('متوسط الفاتورة',
                        Formatters.formatCurrency(report.averageInvoice)),
                  ],
                ),
                pw.SizedBox(height: 24),

                // ─── Hourly Sales Table ───
                pw.Text(
                  'المبيعات بالساعة',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (report.chartData.isEmpty)
                  pw.Text('لا توجد مبيعات',
                      style: pw.TextStyle(color: PdfColors.grey600))
                else
                  pw.TableHelper.fromTextArray(
                    headers: ['الساعة', 'المبيعات'],
                    data: report.chartData
                        .map((p) => [
                              '${p.hour}:00',
                              Formatters.formatCurrency(p.sales),
                            ])
                        .toList(),
                    headerAlignment: pw.Alignment.center,
                    cellAlignment: pw.Alignment.center,
                    border: pw.TableBorder.all(
                        color: PdfColors.grey400, width: 0.5),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellPadding: const pw.EdgeInsets.all(6),
                  ),
                pw.SizedBox(height: 24),

                // ─── Top Products ───
                pw.Text(
                  AppStrings.topProducts,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (report.topProducts.isEmpty)
                  pw.Text('لا توجد منتجات مبيعة',
                      style: pw.TextStyle(color: PdfColors.grey600))
                else
                  pw.TableHelper.fromTextArray(
                    headers: ['#', 'المنتج', 'الكمية', 'الإيراد'],
                    data: report.topProducts
                        .asMap()
                        .entries
                        .map((e) => [
                              '${e.key + 1}',
                              e.value.name,
                              '${e.value.quantitySold}',
                              Formatters.formatCurrency(e.value.revenue),
                            ])
                        .toList(),
                    headerAlignment: pw.Alignment.center,
                    cellAlignment: pw.Alignment.center,
                    border: pw.TableBorder.all(
                        color: PdfColors.grey400, width: 0.5),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellPadding: const pw.EdgeInsets.all(6),
                  ),

                pw.SizedBox(height: 32),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'تم إنشاؤه بواسطة تطبيق فاتورة',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  // Save to temp file and share
  try {
    final dir = await getTemporaryDirectory();
    final fileName =
        'fatura-report-${report.date.toIso8601String().split('T')[0]}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'تقرير مبيعات يوم ${Formatters.formatDate(report.date)}',
    );
  } catch (e) {
    // Fallback: open print dialog
    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Fatura Daily Report',
      );
    }
  }
}

pw.Widget _pdfStat(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );
}