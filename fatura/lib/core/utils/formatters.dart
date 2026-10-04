/// formatters.dart — Utility formatters for Fatura
library;

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Format currency with symbol
  static String formatCurrency(
    double amount, {
    String symbol = 'ج.م',
    int decimalDigits = 2,
    String locale = 'ar_EG',
  }) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      locale: locale,
    );
    return formatter.format(amount);
  }

  /// Format date in Arabic
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar_EG').format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm', 'ar_EG').format(date);
  }

  /// Format time only
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'ar_EG').format(date);
  }

  /// Generate invoice number: INV-YYYYMMDD-XXXX
  static String generateInvoiceNumber(int sequence) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'INV-$dateStr-${sequence.toString().padLeft(4, '0')}';
  }
}