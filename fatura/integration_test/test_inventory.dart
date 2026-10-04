/// test_inventory.dart — Integration tests for inventory (product CRUD)
///
/// Tests:
/// 1. Add product (name, price, qty, barcode) → save → appears in list
/// 2. Edit product → updated in list
/// 3. Delete product → disappears from list
/// 4. Search for product
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fatura/core/database/database.dart' as db;
import 'package:fatura/features/inventory/providers/inventory_providers.dart';
import 'package:fatura/features/inventory/presentation/screens/product_list_screen.dart';
import 'package:fatura/features/inventory/presentation/screens/add_edit_product_screen.dart';

import 'test_helpers.dart';

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = createTestDatabase();
    await seedStoreAndOwner(database);
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildHarness(Widget home) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: MaterialApp(home: home),
    );
  }

  testWidgets('Product list shows empty state initially', (tester) async {
    await tester.pumpWidget(buildHarness(const ProductListScreen()));
    await tester.pumpAndSettle();

    // The search bar should be visible
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('بحث بالاسم أو الباركود...'), findsOneWidget);
  });

  testWidgets('Add product via DAO → appears in product list', (tester) async {
    // Seed a product directly via DAO
    await seedProduct(database,
        name: 'ماء معدني 0.5 لتر',
        price: 5.0,
        quantity: 50,
        barcode: '6001234567890');

    await tester.pumpWidget(buildHarness(const ProductListScreen()));
    await tester.pumpAndSettle();

    // The product should appear in the list
    expect(find.text('ماء معدني 0.5 لتر'), findsOneWidget);
    expect(find.text('5.00 ج.م'), findsOneWidget);
    expect(find.textContaining('الكمية: 50'), findsOneWidget);
  });

  testWidgets('Add product via AddEditProductScreen form → saved in DB',
      (tester) async {
    await tester.pumpWidget(buildHarness(const AddEditProductScreen()));
    await tester.pumpAndSettle();

    // Fill in the form
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'شاي أخضر',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '6111222333444',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '12.50',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      '30',
    );
    await tester.enterText(
      find.byType(TextFormField).at(4),
      '5',
    );
    await tester.enterText(
      find.byType(TextFormField).at(5),
      'مشروبات',
    );

    // Tap save button
    await tester.ensureVisible(find.text('حفظ'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Verify product was saved in DB
    final products = await database.productsDao.getAllProducts();
    expect(products.length, 1, reason: 'One product should have been saved');
    expect(products.first.name, 'شاي أخضر');
    expect(products.first.barcode, '6111222333444');
    expect(products.first.price, 12.50);
    expect(products.first.quantity, 30);
    expect(products.first.minQuantity, 5);
    expect(products.first.category, 'مشروبات');
  });

  testWidgets('Edit product → updated in DB and list', (tester) async {
    // Seed a product
    final productId = await seedProduct(database,
        name: 'منتج أصلي', price: 10.0, quantity: 20);

    // Get the product
    final product = await database.productsDao.getProductById(productId);
    expect(product, isNotNull);
    expect(product!.name, 'منتج أصلي');

    // Edit directly via DAO
    final updatedProduct = db.Product(
      id: productId,
      name: 'منتج معدل',
      barcode: product.barcode,
      price: 15.0,
      cost: product.cost,
      quantity: 25,
      minQuantity: product.minQuantity,
      category: product.category,
      unit: product.unit,
      imagePath: product.imagePath,
      createdAt: product.createdAt,
      updatedAt: DateTime.now(),
    );
    final success = await database.productsDao.updateProduct(updatedProduct);
    expect(success, isTrue);

    // Verify in DB
    final updated = await database.productsDao.getProductById(productId);
    expect(updated!.name, 'منتج معدل');
    expect(updated.price, 15.0);
    expect(updated.quantity, 25);
  });

  testWidgets('Delete product → removed from DB', (tester) async {
    final productId = await seedProduct(database,
        name: 'منتج للحذف', price: 3.0, quantity: 10);

    // Verify it exists
    var products = await database.productsDao.getAllProducts();
    expect(products.length, 1);

    // Delete
    final deletedCount = await database.productsDao.deleteProduct(productId);
    expect(deletedCount, 1);

    // Verify it's gone
    products = await database.productsDao.getAllProducts();
    expect(products, isEmpty);
  });

  testWidgets('Search filters products by name', (tester) async {
    await seedProduct(database, name: 'ماء معدني', price: 5, quantity: 50);
    await seedProduct(database, name: 'شاي أخضر', price: 12, quantity: 30);
    await seedProduct(database, name: 'بسكويت', price: 8, quantity: 100,
        barcode: '6009999999999');

    await tester.pumpWidget(buildHarness(const ProductListScreen()));
    await tester.pumpAndSettle();

    // All 3 products visible
    expect(find.text('ماء معدني'), findsOneWidget);
    expect(find.text('شاي أخضر'), findsOneWidget);
    expect(find.text('بسكويت'), findsOneWidget);

    // Type search query
    await tester.enterText(find.byType(TextField), 'ماء');
    await tester.pumpAndSettle();

    // Only "ماء معدني" should be visible
    expect(find.text('ماء معدني'), findsOneWidget);
    expect(find.text('شاي أخضر'), findsNothing);
    expect(find.text('بسكويت'), findsNothing);
  });

  testWidgets('Search by barcode works', (tester) async {
    await seedProduct(database, name: 'منتج A', price: 5, quantity: 10,
        barcode: '1111111111111');
    await seedProduct(database, name: 'منتج B', price: 5, quantity: 10,
        barcode: '2222222222222');

    await tester.pumpWidget(buildHarness(const ProductListScreen()));
    await tester.pumpAndSettle();

    // Search by barcode
    await tester.enterText(find.byType(TextField), '2222');
    await tester.pumpAndSettle();

    expect(find.text('منتج B'), findsOneWidget);
    expect(find.text('منتج A'), findsNothing);
  });

  testWidgets('Low stock badge appears for products at or below min quantity',
      (tester) async {
    await seedProduct(database,
        name: 'منتج منخفض', price: 5, quantity: 3, minQuantity: 5,
        barcode: 'AAA111');

    await tester.pumpWidget(buildHarness(const ProductListScreen()));
    await tester.pumpAndSettle();

    // Should show "منخفض" badge
    expect(find.text('منخفض'), findsOneWidget);
  });

  testWidgets('Out of stock badge appears for products with 0 quantity',
      (tester) async {
    await seedProduct(database,
        name: 'منتج نفد', price: 5, quantity: 0, minQuantity: 5,
        barcode: 'BBB222');

    await tester.pumpWidget(buildHarness(const ProductListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('نفد'), findsOneWidget);
  });

  testWidgets('In stock badge for products above min quantity', (tester) async {
    await seedProduct(database,
        name: 'منتج متاح', price: 5, quantity: 100, minQuantity: 5,
        barcode: 'CCC333');

    await tester.pumpWidget(buildHarness(const ProductListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('متاح'), findsOneWidget);
  });
}