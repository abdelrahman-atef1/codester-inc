/// tables.dart — Drift table definitions for Fatura POS
///
/// All tables for the Fatura database:
/// - stores, users, products, invoices, invoice_items, activity_log, settings
library;

import 'package:drift/drift.dart';

/// ===== STORES (المتجر) =====
class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get type => text().nullable()(); // كشك/متجر/صناع يدوي/أخرى
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('EGP'))();
  TextColumn get language => text().withDefault(const Constant('ar'))();
  BoolColumn get taxEnabled => boolean().withDefault(const Constant(false))();
  RealColumn get taxRate => real().withDefault(const Constant(0))();
  TextColumn get logoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// ===== USERS (الموظفين) =====
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId => integer().nullable().references(Stores, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get pinHash => text()(); // SHA-256(salt + pin) hex string
  TextColumn get pinSalt => text()(); // random 16 bytes hex string
  TextColumn get role => text()(); // owner, pos_clerk, inventory_manager, viewer
  TextColumn get permissions => text().nullable()(); // JSON array
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLogin => dateTime().nullable()();
}

/// ===== PRODUCTS (المنتجات) =====
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable()();
  RealColumn get price => real()();
  RealColumn get cost => real().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get minQuantity => integer().withDefault(const Constant(5))();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('قطعة'))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// ===== INVOICES (الفواتير) =====
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get storeId => integer().nullable().references(Stores, #id)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  TextColumn get paymentMethod => text().nullable()(); // cash, card, wallet
  RealColumn get amountPaid => real().nullable()();
  RealColumn get change => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))(); // draft, completed, refunded
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // synced, pending
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ===== SYNC_METADATA (بيانات المزامنة) =====
class SyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get pendingCount => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text().withLength(min: 1, max: 200)();
  TextColumn get deviceName => text().nullable()();
  TextColumn get syncRole => text()(); // owner, employee
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// ===== INVOICE_ITEMS (عناصر الفاتورة) =====
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().nullable().references(Products, #id)();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer()();
  RealColumn get total => real()();
}

/// ===== ACTIVITY_LOG (سجل النشاط) =====
class ActivityLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get action => text()(); // sale, edit_product, add_product, login, etc
  TextColumn get entityType => text().nullable()(); // invoice, product, user
  IntColumn get entityId => integer().nullable()();
  TextColumn get details => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ===== SETTINGS (الإعدادات) =====
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text().nullable()();
}

/// ===== FEEDBACKS (الملاحظات والاقتراحات) =====
class Feedbacks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // bug, feature_request, improvement
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text()();
  TextColumn get priority => text().nullable()(); // low, medium, high
  TextColumn get status => text().withDefault(const Constant('new'))(); // new, read, resolved
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}