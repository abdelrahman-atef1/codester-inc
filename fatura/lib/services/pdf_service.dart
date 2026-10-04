/// pdf_service.dart — Invoice PDF generation + save + share.
///
/// Builds a styled A4/80mm invoice PDF using the `pdf` package, mirroring
/// the Bold Executive receipt: shop header, meta grid, items table,
/// subtotal/VAT/discount, emphasized total bar, QR verification code.
///
/// Outputs:
/// - [generateInvoicePdf] → raw PDF bytes (Uint8List) — pure, testable.
/// - [saveInvoicePdf]     → writes bytes to the app documents dir, returns File.
/// - [shareInvoicePdf]    → shares the saved PDF (WhatsApp and other targets)
///                          via `share_plus`.
library;

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/repository.dart' show FullInvoice;

/// Result of saving/sharing a PDF, surfaced to the UI.
class PdfResult {
  const PdfResult._(this.ok, this.message, {this.file});

  factory PdfResult.success(File file) =>
      PdfResult._(true, 'تم إنشاء ملف PDF', file: file);
  factory PdfResult.failure(String message) => PdfResult._(false, message);

  final bool ok;
  final String message;
  final File? file;
}

/// Invoice PDF generator / persistence / sharing.
class PdfService {
  PdfService();

  /// Shop identity. Will be sourced from settings in a later slice.
  static const String shopName = 'فاتورة — نقطة البيع';
  static const String shopPhone = '0100 000 0000';

  /// Build the invoice PDF bytes (pure — no I/O, unit-testable).
  Future<List<int>> generateInvoicePdf(FullInvoice invoice) {
    final doc = pw.Document();
    final dt =
        DateFormat('yyyy-MM-dd HH:mm').format(invoice.invoice.createdAt);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Shop header
              pw.Center(
                child: pw.Text(shopName,
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text(shopPhone)),
              pw.Center(child: pw.Text(dt)),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text('Invoice ${invoice.invoice.invoiceNumber}',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Items table
              pw.TableHelper.fromTextArray(
                headers: const ['Total', 'Price', 'Qty', 'Item'],
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignments: {
                  0: pw.Alignment.centerRight,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                },
                data: [
                  for (final item in invoice.items)
                    [
                      item.total.toStringAsFixed(2),
                      item.price.toStringAsFixed(2),
                      '${item.quantity}',
                      item.name,
                    ],
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Totals
              _totalRow('Subtotal', invoice.invoice.subtotal),
              _totalRow('VAT (14%)', invoice.invoice.tax),
              if (invoice.invoice.discount > 0)
                _totalRow('Discount', -invoice.invoice.discount),
              pw.SizedBox(height: 6),
              pw.Container(
                color: PdfColors.grey800,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.invoice.total.toStringAsFixed(2),
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // QR verification code + footer
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: invoice.invoice.invoiceNumber,
                  width: 100,
                  height: 100,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('Thank you for your business')),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  pw.Widget _totalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(amount.toStringAsFixed(2)),
        ],
      ),
    );
  }

  /// Save the invoice PDF to the app's documents directory.
  /// Returns the written [File] on success.
  Future<PdfResult> saveInvoicePdf(FullInvoice invoice) async {
    try {
      final bytes = await generateInvoicePdf(invoice);
      final dir = await getApplicationDocumentsDirectory();
      final safeNumber =
          invoice.invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
      final file = File('${dir.path}/invoice_$safeNumber.pdf');
      await file.writeAsBytes(bytes);
      return PdfResult.success(file);
    } catch (e) {
      return PdfResult.failure('فشل حفظ ملف PDF: $e');
    }
  }

  /// Generate, save and share the invoice PDF (e.g. via WhatsApp) using the
  /// platform share sheet.
  Future<PdfResult> shareInvoicePdf(FullInvoice invoice) async {
    final saved = await saveInvoicePdf(invoice);
    if (!saved.ok || saved.file == null) return saved;
    try {
      await Share.shareXFiles(
        [XFile(saved.file!.path)],
        text: 'فاتورة ${invoice.invoice.invoiceNumber}',
      );
      return PdfResult._(true, 'تمت مشاركة ملف PDF', file: saved.file);
    } catch (e) {
      return PdfResult.failure('فشلت مشاركة ملف PDF: $e');
    }
  }
}
