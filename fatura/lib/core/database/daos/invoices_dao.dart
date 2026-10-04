/// invoices_dao.dart — DAO for invoices table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'invoices_dao.g.dart';

@DriftAccessor(tables: [Invoices])
class InvoicesDao extends DatabaseAccessor<AppDatabase>
    with _$InvoicesDaoMixin {
  InvoicesDao(super.db);

  Future<List<Invoice>> getAllInvoices() =>
      (select(invoices)..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .get();

  Stream<List<Invoice>> watchAllInvoices() =>
      (select(invoices)..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .watch();

  Future<Invoice?> getInvoiceById(int id) =>
      (select(invoices)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<Invoice?> getInvoiceByNumber(String number) =>
      (select(invoices)..where((i) => i.invoiceNumber.equals(number)))
          .getSingleOrNull();

  Stream<Invoice?> watchInvoiceById(int id) =>
      (select(invoices)..where((i) => i.id.equals(id))).watchSingleOrNull();

  Future<List<Invoice>> getInvoicesByDateRange(
      DateTime start, DateTime end) {
    return (select(invoices)
          ..where((i) =>
              i.createdAt.isBetweenValues(start, end))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  Future<List<Invoice>> getInvoicesByStatus(String status) {
    return (select(invoices)
          ..where((i) => i.status.equals(status))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  Future<List<Invoice>> getInvoicesByUser(int userId) {
    return (select(invoices)
          ..where((i) => i.userId.equals(userId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  Stream<List<Invoice>> watchTodayInvoices() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(invoices)
          ..where((i) =>
              i.createdAt.isBetweenValues(start, end) &
              i.status.equals('completed'))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  Future<int> insertInvoice(InvoicesCompanion companion) =>
      into(invoices).insert(companion);

  Future<bool> updateInvoice(Invoice invoice) =>
      update(invoices).replace(invoice);

  Future<int> deleteInvoice(int id) =>
      (delete(invoices)..where((i) => i.id.equals(id))).go();

  Future<void> updateStatus(int id, String status) {
    return (update(invoices)..where((i) => i.id.equals(id)))
        .write(InvoicesCompanion(status: Value(status)));
  }

  // ===== Sync Status Helpers =====

  Future<List<Invoice>> getPendingInvoices() {
    return (select(invoices)
          ..where((i) => i.syncStatus.equals('pending'))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  Future<int> getPendingInvoicesCount() {
    final count = invoices.syncStatus.count();
    final query = selectOnly(invoices)
      ..addColumns([count])
      ..where(invoices.syncStatus.equals('pending'));
    final result = query.get();
    return result.then((rows) => rows.first.read(count) ?? 0);
  }

  Future<void> markInvoiceSynced(int id) {
    return (update(invoices)..where((i) => i.id.equals(id)))
        .write(const InvoicesCompanion(syncStatus: Value('synced')));
  }

  Future<void> markAllInvoicesSynced(List<int> ids) async {
    for (final id in ids) {
      await markInvoiceSynced(id);
    }
  }

  Future<void> markInvoicePending(int id) {
    return (update(invoices)..where((i) => i.id.equals(id)))
        .write(const InvoicesCompanion(syncStatus: Value('pending')));
  }

  /// Get daily sales summary
  Future<double> getTotalSalesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final result = await (select(invoices)
          ..where((i) =>
              i.createdAt.isBetweenValues(start, end) &
              i.status.equals('completed')))
        .get();
    return result.fold<double>(0.0, (sum, inv) => sum + inv.total);
  }

  /// Get invoice count for date
  Future<int> getInvoiceCountForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final result = await (select(invoices)
          ..where((i) =>
              i.createdAt.isBetweenValues(start, end) &
              i.status.equals('completed')))
        .get();
    return result.length;
  }
}