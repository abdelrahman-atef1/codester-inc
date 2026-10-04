/// test_helpers.dart — Shared setup for Fatura tests
///
/// Provides an in-memory Drift database, ProviderContainer helpers,
/// and common seeding functions.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/core/database/database.dart' as db;
import 'package:fatura/core/utils/pin_hasher.dart';
import 'package:fatura/features/inventory/providers/inventory_providers.dart';

// Re-export the Companion types from the generated database file
export 'package:fatura/core/database/database.dart'
    show StoresCompanion, UsersCompanion, ProductsCompanion, ActivityLogCompanion, InvoicesCompanion, InvoiceItemsCompanion;

/// Creates an in-memory AppDatabase for testing.
db.AppDatabase createTestDatabase() {
  return db.AppDatabase.forTesting(NativeDatabase.memory());
}

/// Seeds a store + owner user with a known PIN into the database.
/// Returns the created store ID and user ID.
Future<({int storeId, int userId, String pin})> seedStoreAndOwner(
  db.AppDatabase database, {
  String pin = '1234',
  String storeName = 'متجر الاختبار',
}) async {
  final storeId = await database.storesDao.insertStore(
    db.StoresCompanion(
      name: Value(storeName),
      type: const Value('متجر'),
      address: const Value('شارع الاختبار'),
      currency: const Value('EGP'),
      taxEnabled: const Value(true),
      taxRate: const Value(14.0),
    ),
  );

  final salt = generateSalt();
  final pinHash = hashPin(pin, salt);

  final userId = await database.usersDao.insertUser(
    db.UsersCompanion(
      storeId: Value(storeId),
      name: const Value('المالك'),
      pinHash: Value(pinHash),
      pinSalt: Value(salt),
      role: const Value('owner'),
    ),
  );

  return (storeId: storeId, userId: userId, pin: pin);
}

/// Seeds a product into the database.
Future<int> seedProduct(
  db.AppDatabase database, {
  String name = 'ماء معدني 0.5 لتر',
  double price = 5.0,
  int quantity = 50,
  String? barcode = '6001234567890',
  int minQuantity = 5,
  String category = 'مشروبات',
  String unit = 'قطعة',
}) async {
  return database.productsDao.insertProduct(
    db.ProductsCompanion(
      name: Value(name),
      barcode: Value(barcode),
      price: Value(price),
      quantity: Value(quantity),
      minQuantity: Value(minQuantity),
      category: Value(category),
      unit: Value(unit),
    ),
  );
}

/// ProviderContainer with overridden database for unit tests.
ProviderContainer createTestContainer(db.AppDatabase database) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
    ],
  );
}

/// Wraps a widget with ProviderScope using a test database override.
Widget wrapWithProviders(
  Widget child, {
  required db.AppDatabase database,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      ...overrides,
    ],
    child: child,
  );
}

/// Helper to pump a widget and settle animations.
Future<void> pumpAndSettleFixed(
  WidgetTester tester,
  Widget widget, {
  Duration duration = const Duration(seconds: 1),
}) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle(duration);
}