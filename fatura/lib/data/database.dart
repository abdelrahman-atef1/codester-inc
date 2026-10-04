/// database.dart — Drift (SQLite) database for the Bold Executive POS flow.
///
/// Self-contained database used by the Stitch-designed screens:
/// - pos_dashboard_screen.dart
/// - invoice_screen.dart
///
/// Tables:
/// - pos_categories (SQL name: categories)
/// - pos_products   (SQL name: products)
/// - pos_invoices   (SQL name: invoices)
/// - pos_invoice_items (SQL name: invoice_items)
///
/// NOTE: Dart class names intentionally differ from the legacy
/// core/database tables to avoid symbol collisions at import sites.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// ===== CATEGORIES (الفئات) =====
@DataClassName('Category')
@TableIndex(name: 'categories_name_idx', columns: {#name})
class Categories extends Table {
  @override
  String get tableName => 'categories';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get icon => text().withDefault(const Constant('category'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// ===== PRODUCTS (المنتجات) =====
@DataClassName('Product')
class Products extends Table {
  @override
  String get tableName => 'products';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable()();
  RealColumn get price => real()();
  TextColumn get unit => text().withDefault(const Constant('قطعة'))();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get icon => text().withDefault(const Constant('inventory_2'))();
  IntColumn get colorHue => integer().withDefault(const Constant(0))();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
}

/// ===== INVOICES (الفواتير) =====
@DataClassName('Invoice')
class Invoices extends Table {
  @override
  String get tableName => 'invoices';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  TextColumn get customerName => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))();
  TextColumn get status => text().withDefault(const Constant('paid'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// ===== INVOICE_ITEMS (عناصر الفاتورة) =====
@DataClassName('InvoiceItem')
class InvoiceItems extends Table {
  @override
  String get tableName => 'invoice_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().nullable().references(Products, #id)();
  TextColumn get name => text()();
  TextColumn get subtitle => text().nullable()();
  RealColumn get price => real()();
  IntColumn get quantity => integer()();
  RealColumn get total => real()();
}

@DriftDatabase(tables: [Categories, Products, Invoices, InvoiceItems])
class PosDatabase extends _$PosDatabase {
  PosDatabase() : super(_openConnection());

  PosDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fatura_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
