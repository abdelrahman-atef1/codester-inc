/// invoice_providers.dart — Riverpod providers for invoices feature
///
/// Provides streams for invoice list, detail, and related data.
/// Uses existing Drift DAOs (InvoicesDao, InvoiceItemsDao, StoresDao, UsersDao).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/database/daos/invoices_dao.dart';
import '../../../../core/database/daos/invoice_items_dao.dart';
import '../../../../core/database/daos/stores_dao.dart';
import '../../../../core/database/daos/users_dao.dart';
import '../../inventory/providers/inventory_providers.dart'
    show appDatabaseProvider;
// re-export so other features can import from here
export '../../inventory/providers/inventory_providers.dart'
    show appDatabaseProvider;

// ─── DAOs ───

final invoicesDaoProvider = Provider<InvoicesDao>((ref) {
  return InvoicesDao(ref.watch(appDatabaseProvider));
});

final invoiceItemsDaoProvider = Provider<InvoiceItemsDao>((ref) {
  return InvoiceItemsDao(ref.watch(appDatabaseProvider));
});

final storesDaoProvider = Provider<StoresDao>((ref) {
  return StoresDao(ref.watch(appDatabaseProvider));
});

final usersDaoProvider = Provider<UsersDao>((ref) {
  return UsersDao(ref.watch(appDatabaseProvider));
});

// ─── Filter State ───

/// Filter period for invoice list
enum InvoiceFilter { today, week, month, all }

final invoiceFilterProvider =
    StateProvider<InvoiceFilter>((ref) => InvoiceFilter.today);

/// Search query for invoice list
final invoiceSearchProvider = StateProvider<String>((ref) => '');

// ─── Invoice List ───

/// Reactive invoice list filtered by period + search query
final invoiceListProvider =
    StreamProvider<List<db.Invoice>>((ref) {
  final dao = ref.watch(invoicesDaoProvider);
  final filter = ref.watch(invoiceFilterProvider);
  final query = ref.watch(invoiceSearchProvider);

  final now = DateTime.now();
  DateTime start;
  switch (filter) {
    case InvoiceFilter.today:
      start = DateTime(now.year, now.month, now.day);
      break;
    case InvoiceFilter.week:
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      break;
    case InvoiceFilter.month:
      start = DateTime(now.year, now.month, 1);
      break;
    case InvoiceFilter.all:
      start = DateTime(2000);
      break;
  }

  return dao.watchAllInvoices().map((invoices) {
    final filtered = invoices.where((inv) {
      final inRange = !inv.createdAt.isBefore(start);
      if (!inRange) return false;
      if (query.isNotEmpty) {
        return inv.invoiceNumber.toLowerCase().contains(query.toLowerCase());
      }
      return true;
    }).toList();
    return filtered;
  });
});

// ─── Invoice Detail ───

/// Composite model for invoice detail (invoice + items + store + seller)
class InvoiceDetail {
  final db.Invoice invoice;
  final List<db.InvoiceItem> items;
  final db.Store? store;
  final db.User? seller;

  const InvoiceDetail({
    required this.invoice,
    required this.items,
    this.store,
    this.seller,
  });
}

/// Fetch full invoice detail by ID (non-stream, one-shot)
final invoiceDetailProvider =
    FutureProvider.family<InvoiceDetail, int>((ref, id) async {
  final invoicesDao = ref.watch(invoicesDaoProvider);
  final itemsDao = ref.watch(invoiceItemsDaoProvider);
  final storesDao = ref.watch(storesDaoProvider);
  final usersDao = ref.watch(usersDaoProvider);

  final invoice = await invoicesDao.getInvoiceById(id);
  if (invoice == null) {
    throw Exception('Invoice not found');
  }

  final items = await itemsDao.getItemsByInvoice(id);

  db.Store? store;
  if (invoice.storeId != null) {
    store = await storesDao.getStoreById(invoice.storeId!);
  }

  db.User? seller;
  if (invoice.userId != null) {
    seller = await usersDao.getUserById(invoice.userId!);
  }

  return InvoiceDetail(
    invoice: invoice,
    items: items,
    store: store,
    seller: seller,
  );
});

/// Reactive stream of invoice items for a given invoice
final invoiceItemsProvider =
    StreamProvider.family<List<db.InvoiceItem>, int>((ref, invoiceId) {
  final dao = ref.watch(invoiceItemsDaoProvider);
  return dao.watchItemsByInvoice(invoiceId);
});

// ─── Delete Invoice ───

/// Delete invoice + cascade items, return true on success
final deleteInvoiceProvider =
    FutureProvider.family<bool, int>((ref, id) async {
  final itemsDao = ref.watch(invoiceItemsDaoProvider);
  final invoicesDao = ref.watch(invoicesDaoProvider);
  await itemsDao.deleteItemsByInvoice(id);
  await invoicesDao.deleteInvoice(id);
  return true;
});