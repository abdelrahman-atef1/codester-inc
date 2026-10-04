/// report_providers.dart — Riverpod providers for reports feature
///
/// Provides daily sales data, top products, and chart-ready aggregations.
/// Uses existing Drift DAOs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../invoices/providers/invoice_providers.dart'
    show invoicesDaoProvider, invoiceItemsDaoProvider;

// ─── Report Date State ───

/// The date for the daily report (defaults to today)
final reportDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ─── Daily Report Model ───

class DailyReport {
  final DateTime date;
  final double totalSales;
  final int invoiceCount;
  final double averageInvoice;
  final List<DailySalesPoint> chartData;
  final List<TopProduct> topProducts;

  const DailyReport({
    required this.date,
    required this.totalSales,
    required this.invoiceCount,
    required this.averageInvoice,
    required this.chartData,
    required this.topProducts,
  });
}

/// One data point for the sales chart (hourly breakdown)
class DailySalesPoint {
  final int hour;
  final double sales;

  const DailySalesPoint({required this.hour, required this.sales});
}

/// Top-selling product aggregate
class TopProduct {
  final String name;
  final int quantitySold;
  final double revenue;

  const TopProduct({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });
}

// ─── Daily Report Provider ───

final dailyReportProvider =
    FutureProvider<DailyReport>((ref) async {
  final invoicesDao = ref.watch(invoicesDaoProvider);
  final date = ref.watch(reportDateProvider);

  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));

  // Get all completed invoices for the day
  final invoices = await invoicesDao.getInvoicesByDateRange(start, end);
  final completed =
      invoices.where((i) => i.status == 'completed').toList();

  final totalSales =
      completed.fold<double>(0.0, (sum, inv) => sum + inv.total);
  final invoiceCount = completed.length;
  final averageInvoice = invoiceCount > 0 ? totalSales / invoiceCount : 0.0;

  // Build hourly chart data
  final hourlyMap = <int, double>{
    for (var h = 0; h < 24; h++) h: 0.0,
  };
  for (final inv in completed) {
    final hour = inv.createdAt.hour;
    hourlyMap[hour] = hourlyMap[hour]! + inv.total;
  }
  final chartData = hourlyMap.entries
      .where((e) => e.value > 0)
      .map((e) => DailySalesPoint(hour: e.key, sales: e.value))
      .toList();

  // Top products: aggregate invoice items
  final itemsDao = ref.watch(invoiceItemsDaoProvider);
  final productMap = <String, _ProductAgg>{};
  for (final inv in completed) {
    final items = await itemsDao.getItemsByInvoice(inv.id);
    for (final item in items) {
      final agg = productMap.putIfAbsent(
        item.name,
        () => _ProductAgg(name: item.name, quantity: 0, revenue: 0.0),
      );
      agg.quantity += item.quantity;
      agg.revenue += item.total;
    }
  }
  final topProducts = productMap.values.toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity));
  final top5 = topProducts.take(5).map((a) => TopProduct(
        name: a.name,
        quantitySold: a.quantity,
        revenue: a.revenue,
      )).toList();

  return DailyReport(
    date: date,
    totalSales: totalSales,
    invoiceCount: invoiceCount,
    averageInvoice: averageInvoice,
    chartData: chartData,
    topProducts: top5,
  );
});

class _ProductAgg {
  final String name;
  int quantity;
  double revenue;
  _ProductAgg({required this.name, this.quantity = 0, this.revenue = 0.0});
}

// ─── Top Products Provider (standalone, for reuse) ───

final topProductsProvider =
    FutureProvider.family<List<TopProduct>, DateTime>((ref, date) async {
  final invoicesDao = ref.watch(invoicesDaoProvider);
  final itemsDao = ref.watch(invoiceItemsDaoProvider);

  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  final invoices = await invoicesDao.getInvoicesByDateRange(start, end);
  final completed =
      invoices.where((i) => i.status == 'completed').toList();

  final productMap = <String, _ProductAgg>{};
  for (final inv in completed) {
    final items = await itemsDao.getItemsByInvoice(inv.id);
    for (final item in items) {
      final agg = productMap.putIfAbsent(
        item.name,
        () => _ProductAgg(name: item.name, quantity: 0, revenue: 0.0),
      );
      agg.quantity += item.quantity;
      agg.revenue += item.total;
    }
  }
  final sorted = productMap.values.toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity));
  return sorted.take(5).map((a) => TopProduct(
        name: a.name,
        quantitySold: a.quantity,
        revenue: a.revenue,
      )).toList();
});

// ─── Weekly Chart Data (for bar chart in daily report) ───

class WeeklySalesPoint {
  final DateTime date;
  final double sales;
  final int invoiceCount;

  const WeeklySalesPoint({
    required this.date,
    required this.sales,
    required this.invoiceCount,
  });
}

final weeklySalesProvider =
    FutureProvider<List<WeeklySalesPoint>>((ref) async {
  final invoicesDao = ref.watch(invoicesDaoProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final points = <WeeklySalesPoint>[];
  for (var i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final start = day;
    final end = day.add(const Duration(days: 1));
    final invoices = await invoicesDao.getInvoicesByDateRange(start, end);
    final completed =
        invoices.where((i) => i.status == 'completed').toList();
    final sales = completed.fold<double>(0.0, (s, inv) => s + inv.total);
    points.add(WeeklySalesPoint(
      date: day,
      sales: sales,
      invoiceCount: completed.length,
    ));
  }
  return points;
});