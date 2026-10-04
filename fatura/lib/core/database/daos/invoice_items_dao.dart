/// invoice_items_dao.dart — DAO for invoice_items table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'invoice_items_dao.g.dart';

@DriftAccessor(tables: [InvoiceItems])
class InvoiceItemsDao extends DatabaseAccessor<AppDatabase>
    with _$InvoiceItemsDaoMixin {
  InvoiceItemsDao(super.db);

  Future<List<InvoiceItem>> getItemsByInvoice(int invoiceId) {
    return (select(invoiceItems)
          ..where((ii) => ii.invoiceId.equals(invoiceId)))
        .get();
  }

  Stream<List<InvoiceItem>> watchItemsByInvoice(int invoiceId) {
    return (select(invoiceItems)
          ..where((ii) => ii.invoiceId.equals(invoiceId)))
        .watch();
  }

  Future<int> insertItem(InvoiceItemsCompanion companion) =>
      into(invoiceItems).insert(companion);

  Future<void> insertItems(List<InvoiceItemsCompanion> companions) {
    return batch((b) => b.insertAll(invoiceItems, companions));
  }

  Future<int> deleteItem(int id) =>
      (delete(invoiceItems)..where((ii) => ii.id.equals(id))).go();

  Future<int> deleteItemsByInvoice(int invoiceId) =>
      (delete(invoiceItems)..where((ii) => ii.invoiceId.equals(invoiceId)))
          .go();
}