/// database.dart — Drift database definition for Fatura
///
/// Main database class with all tables and DAOs.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

// DAOs — imported and re-exported so consumers can access them
// via `package:.../database.dart' as db`.
import 'daos/stores_dao.dart';
import 'daos/users_dao.dart';
import 'daos/products_dao.dart';
import 'daos/invoices_dao.dart';
import 'daos/invoice_items_dao.dart';
import 'daos/activity_log_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/feedbacks_dao.dart';
import 'daos/sync_metadata_dao.dart';

// Re-export DAOs and tables so `import database.dart as db` gives access.
export 'daos/stores_dao.dart' show StoresDao;
export 'daos/users_dao.dart' show UsersDao;
export 'daos/products_dao.dart' show ProductsDao;
export 'daos/invoices_dao.dart' show InvoicesDao;
export 'daos/invoice_items_dao.dart' show InvoiceItemsDao;
export 'daos/activity_log_dao.dart' show ActivityLogDao;
export 'daos/settings_dao.dart' show SettingsDao;
export 'daos/feedbacks_dao.dart' show FeedbacksDao;
export 'daos/sync_metadata_dao.dart' show SyncMetadataDao;
export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Stores,
    Users,
    Products,
    Invoices,
    InvoiceItems,
    ActivityLog,
    Settings,
    Feedbacks,
    SyncMetadata,
  ],
  daos: [
    StoresDao,
    UsersDao,
    ProductsDao,
    InvoicesDao,
    InvoiceItemsDao,
    ActivityLogDao,
    SettingsDao,
    FeedbacksDao,
    SyncMetadataDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(feedbacks);
          }
          if (from < 3) {
            // Add sync_metadata table
            await m.createTable(syncMetadata);
            // Add sync_status column to invoices (default 'pending')
            await m.addColumn(
                invoices, invoices.syncStatus);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fatura.db'));
    return NativeDatabase.createInBackground(file);
  });
}