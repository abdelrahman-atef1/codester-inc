/// printer_service.dart — Bluetooth thermal receipt printing (ESC/POS).
///
/// Supports 58mm and 80mm thermal printers over Bluetooth SPP via
/// `blue_thermal_printer`, with byte-level receipt composition from
/// `esc_pos_utils_plus`. Falls back to the system print dialog (via the
/// `printing` package → PDF) when no Bluetooth printer is paired, so the
/// print button always does something useful — and unit-testable on hosts
/// without Bluetooth.
///
/// Receipt layout mirrors the on-screen Bold Executive receipt:
///   shop name (bold, centered), datetime, itemized rows, totals, QR code.
library;

import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../data/repository.dart' show FullInvoice;

/// Paper width for the target thermal printer.
enum ThermalPaperSize {
  /// 58mm paper — typically 32 monospace characters per line.
  mm58,

  /// 80mm paper — typically 48 characters per line.
  mm80,
}

/// A paired Bluetooth printer discovered via [PrinterService.bondedPrinters].
class ThermalPrinter {
  const ThermalPrinter({
    required this.name,
    required this.address,
    this.paperSize = ThermalPaperSize.mm80,
    this.isConnected = false,
  });

  final String? name;
  final String? address;
  final ThermalPaperSize paperSize;
  final bool isConnected;

  String get displayName =>
      (name == null || name!.isEmpty) ? (address ?? 'طابعة غير معروفة') : name!;
}

/// Result of a print attempt, surfaced to the UI as a SnackBar.
class PrintResult {
  const PrintResult._(this.ok, this.message);

  factory PrintResult.success(String message) => PrintResult._(true, message);
  factory PrintResult.failure(String message) => PrintResult._(false, message);

  final bool ok;
  final String message;
}

/// Bluetooth thermal printer facade.
class PrinterService {
  PrinterService();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// Shop identity shown at the top of the receipt. In a future settings
  /// slice these come from the `settings` table; constants keep this service
  /// self-contained and testable.
  static const String shopName = 'فاتورة — نقطة البيع';
  static const String shopPhone = '0100 000 0000';

  /// Whether the device has Bluetooth and it is available.
  Future<bool> isAvailable() async {
    try {
      return await _bluetooth.isAvailable ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Whether a printer is currently connected.
  Future<bool> isConnected() async {
    try {
      return await _bluetooth.isConnected ?? false;
    } catch (_) {
      return false;
    }
  }

  /// List paired (bonded) Bluetooth devices.
  Future<List<ThermalPrinter>> bondedPrinters() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      return [
        for (final d in devices)
          ThermalPrinter(name: d.name, address: d.address),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Print [invoice] to the first bonded printer found.
  ///
  /// If no printer is paired or the connection fails, returns a failure
  /// [PrintResult] — the caller decides whether to fall back to PDF print.
  Future<PrintResult> printReceipt(
    FullInvoice invoice, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm80,
    String? printerAddress,
  }) async {
    if (!await isAvailable()) {
      return PrintResult.failure('البلوتوث غير متاح على هذا الجهاز');
    }

    // Resolve target device: explicit address, or first bonded device.
    List<BluetoothDevice> devices;
    try {
      devices = await _bluetooth.getBondedDevices();
    } catch (e) {
      return PrintResult.failure('تعذر جلب الطابعات المقترنة: $e');
    }
    if (devices.isEmpty) {
      return PrintResult.failure('لا توجد طابعة مقترنة — قم بإقران الطابعة من إعدادات البلوتوث');
    }
    BluetoothDevice target = devices.first;
    if (printerAddress != null) {
      final match = devices.where((d) => d.address == printerAddress);
      if (match.isNotEmpty) target = match.first;
    }

    // Connect if needed.
    try {
      final alreadyConnected = await isConnected();
      if (!alreadyConnected) {
        await _bluetooth.connect(target);
      }
    } catch (e) {
      return PrintResult.failure('فشل الاتصال بالطابعة: $e');
    }

    // Compose & send ESC/POS bytes.
    try {
      final bytes = await buildReceiptBytes(invoice, paperSize: paperSize);
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
      return PrintResult.success('تم إرسال الإيصال إلى الطابعة');
    } catch (e) {
      return PrintResult.failure('فشل الطباعة: $e');
    }
  }

  /// Disconnect from the printer.
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {/* no-op */}
  }

  // ------------------------------------------------------------------
  // Receipt composition (pure Dart — testable without a device)
  // ------------------------------------------------------------------

  /// Build ESC/POS bytes for [invoice]. Exposed separately from
  /// [printReceipt] so tests can verify layout without Bluetooth.
  Future<List<int>> buildReceiptBytes(
    FullInvoice invoice, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm80,
  }) async {
    final profile = await CapabilityProfile.load();
    final size = paperSize == ThermalPaperSize.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final g = Generator(size, profile);
    var bytes = <int>[];
    final dt = DateFormat('yyyy-MM-dd HH:mm').format(invoice.invoice.createdAt);

    // Header — shop identity.
    bytes += g.text(shopName,
        styles: const PosStyles(
            align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += g.text(shopPhone, styles: const PosStyles(align: PosAlign.center));
    bytes += g.text(dt, styles: const PosStyles(align: PosAlign.center));
    bytes += g.text('فاتورة ${invoice.invoice.invoiceNumber}',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += g.hr();

    // Items — name (left) | qty×price → total (right).
    for (final item in invoice.items) {
      bytes += g.row([
        PosColumn(
            text: item.name,
            width: 7,
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: 'x${item.quantity}', width: 2),
        PosColumn(
            text: item.total.toStringAsFixed(2),
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += g.hr();

    // Totals block.
    bytes += _totalRow(g, 'الإجمالي الفرعي', invoice.invoice.subtotal);
    bytes += _totalRow(g, 'الضريبة (14٪)', invoice.invoice.tax);
    if (invoice.invoice.discount > 0) {
      bytes += _totalRow(g, 'الخصم', -invoice.invoice.discount);
    }
    bytes += g.row([
      PosColumn(
          text: 'الإجمالي',
          width: 6,
          styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
          text: invoice.invoice.total.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(
              bold: true, align: PosAlign.right, height: PosTextSize.size2)),
    ]);
    bytes += g.hr();

    // QR verification code (encodes invoice number) + footer.
    bytes += g.qrcode(invoice.invoice.invoiceNumber,
        align: PosAlign.center, size: QRSize.size6);
    bytes += g.text('شكراً لتسوقكم معنا',
        styles: const PosStyles(align: PosAlign.center));
    bytes += g.feed(2);
    bytes += g.cut();
    return bytes;
  }

  List<int> _totalRow(Generator g, String label, double amount) {
    return g.row([
      PosColumn(text: label, width: 7),
      PosColumn(
          text: amount.toStringAsFixed(2),
          width: 5,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
  }
}
