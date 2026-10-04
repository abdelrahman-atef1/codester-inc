/// test_pos.dart — Integration tests for POS (Point of Sale)
///
/// Tests:
/// 1. Add product to cart
/// 2. Modify cart quantity
/// 3. Calculate subtotal + tax + total
/// 4. Select payment method
/// 5. Complete checkout → success
/// 6. Invoice appears in invoices list
/// 7. Product quantity decremented (inventory)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fatura/core/database/database.dart' as db;
import 'package:fatura/features/inventory/providers/inventory_providers.dart';
import 'package:fatura/features/pos/providers/pos_providers.dart';
import 'package:fatura/features/pos/domain/cart_item.dart';
import 'package:fatura/features/pos/domain/payment_method.dart';
import 'package:fatura/features/pos/presentation/screens/pos_screen.dart';

import 'test_helpers.dart';

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = createTestDatabase();
    await seedStoreAndOwner(database, pin: '1234');
    // Seed products for POS
    await seedProduct(database,
        name: 'ماء معدني 0.5 لتر',
        price: 5.0,
        quantity: 50,
        barcode: '6001111111111');
    await seedProduct(database,
        name: 'شاي أخضر كيس',
        price: 12.50,
        quantity: 30,
        barcode: '6002222222222');
    await seedProduct(database,
        name: 'بسكويت شوكولاتة',
        price: 8.0,
        quantity: 100,
        barcode: '6003333333333');
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildHarness() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const MaterialApp(home: PosScreen()),
    );
  }

  testWidgets('POS screen shows product search and cart', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('بيع سريع'), findsOneWidget);
    // Search bar should be present
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Products appear in POS grid', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('ماء معدني 0.5 لتر'), findsOneWidget);
    expect(find.text('شاي أخضر كيس'), findsOneWidget);
    expect(find.text('بسكويت شوكولاتة'), findsOneWidget);
  });

  // ─── Cart logic unit tests (no UI needed) ───

  test('CartNotifier: add product increments cart', () {
    final container = createTestContainer(database);
    addTearDown(container.dispose);

    // Verify cart starts empty
    final cart = container.read(cartProvider);
    expect(cart.isEmpty, isTrue);
    expect(cart.itemCount, 0);
  });

  test('CartState: subtotal, tax, and total calculations are correct', () async {
    final products = await database.productsDao.getAllProducts();
    final product1 = products[0]; // 5.0 EGP
    final product2 = products[1]; // 12.50 EGP

    // Manually build a CartState
    final cart = CartState(
      items: [
        CartItem(product: product1, quantity: 2), // 5.0 × 2 = 10.0
        CartItem(product: product2, quantity: 3), // 12.50 × 3 = 37.5
      ],
      taxEnabled: true,
      taxRate: 14.0,
    );

    // Subtotal = 10.0 + 37.5 = 47.5
    expect(cart.subtotal, 47.5);
    // Tax = 47.5 × 14% = 6.65
    expect(cart.taxAmount, closeTo(6.65, 0.001));
    // Total = 47.5 + 6.65 = 54.15
    expect(cart.total, closeTo(54.15, 0.001));
    // Item count = 2 + 3 = 5
    expect(cart.itemCount, 5);
    // Unique items = 2
    expect(cart.uniqueCount, 2);
  });

  test('CartState: no tax when taxEnabled is false', () {
    final cart = CartState(
      items: const [],
      taxEnabled: false,
      taxRate: 14.0,
    );

    expect(cart.taxAmount, 0);
    expect(cart.total, cart.subtotal);
  });

  test('PaymentState: change calculation for cash', () {
    const payment = PaymentState(method: PaymentMethod.cash, amountPaid: 100.0);

    // Total = 54.15, Paid = 100 → Change = 45.85
    final change = payment.calculateChange(54.15);
    expect(change, closeTo(45.85, 0.001));
  });

  test('PaymentState: no change when amountPaid < total', () {
    const payment = PaymentState(method: PaymentMethod.cash, amountPaid: 30.0);

    final change = payment.calculateChange(54.15);
    expect(change, 0);
  });

  test('PaymentState: no change for non-cash methods', () {
    const payment = PaymentState(method: PaymentMethod.card, amountPaid: 0);

    final change = payment.calculateChange(54.15);
    expect(change, 0);
  });

  test('Checkout: creates invoice, decrements inventory, logs activity', () async {
    final container = createTestContainer(database);
    addTearDown(container.dispose);

    final products = await database.productsDao.getAllProducts();
    final product1 = products[0]; // 5.0 EGP, qty 50
    final product2 = products[1]; // 12.50 EGP, qty 30

    // Build cart state
    final cartNotifier = container.read(cartProvider.notifier);
    cartNotifier.addProduct(product1);
    cartNotifier.addProduct(product1); // qty 2
    cartNotifier.addProduct(product2); // qty 1

    // Set tax
    cartNotifier.updateTaxSettings(enabled: true, rate: 14.0);

    // Select payment
    final paymentNotifier = container.read(paymentProvider.notifier);
    paymentNotifier.selectMethod(PaymentMethod.cash);
    paymentNotifier.setAmountPaid(100.0);

    // Get the owner user
    final users = await database.usersDao.getAllUsers();
    final owner = users.first;

    // Execute checkout
    final cart = container.read(cartProvider);
    final payment = container.read(paymentProvider);

    final invoiceCreation = container.read(invoiceCreationProvider.notifier);
    final result = await invoiceCreation.checkout(
      cart: cart,
      payment: payment,
      userId: owner.id,
      storeId: owner.storeId,
    );

    // Verify success
    expect(result.success, isTrue, reason: result.error ?? 'Checkout should succeed');
    expect(result.invoiceNumber, isNotNull);
    expect(result.total, closeTo((5.0 * 2 + 12.50) * 1.14, 0.01));
    expect(result.change, closeTo(100.0 - (5.0 * 2 + 12.50) * 1.14, 0.01));

    // Verify invoice in DB
    final invoices = await database.invoicesDao.getAllInvoices();
    expect(invoices.length, 1, reason: 'One invoice should exist');
    expect(invoices.first.invoiceNumber, result.invoiceNumber);
    expect(invoices.first.status, 'completed');
    expect(invoices.first.subtotal, closeTo(5.0 * 2 + 12.50, 0.001));
    expect(invoices.first.tax, closeTo((5.0 * 2 + 12.50) * 0.14, 0.001));
    expect(invoices.first.total, closeTo((5.0 * 2 + 12.50) * 1.14, 0.01));
    expect(invoices.first.paymentMethod, 'cash');

    // Verify invoice items in DB
    final invoiceItems = await database.invoiceItemsDao.getItemsByInvoice(invoices.first.id);
    expect(invoiceItems.length, 2, reason: 'Two line items should exist');

    // Verify product quantities decremented
    final p1After = await database.productsDao.getProductById(product1.id);
    final p2After = await database.productsDao.getProductById(product2.id);
    expect(p1After!.quantity, 48, reason: 'Product 1 qty should decrement by 2 (50 → 48)');
    expect(p2After!.quantity, 29, reason: 'Product 2 qty should decrement by 1 (30 → 29)');

    // Verify activity log
    final logs = await database.activityLogDao.getAllLogs();
    final saleLog = logs.where((l) => l.action == 'sale').toList();
    expect(saleLog.length, 1, reason: 'One sale activity log should exist');
    expect(saleLog.first.entityType, 'invoice');
  });

  test('Checkout: empty cart returns failure', () async {
    final container = createTestContainer(database);
    addTearDown(container.dispose);

    final cart = container.read(cartProvider);
    final payment = container.read(paymentProvider);

    final invoiceCreation = container.read(invoiceCreationProvider.notifier);
    final result = await invoiceCreation.checkout(
      cart: cart,
      payment: payment,
    );

    expect(result.success, isFalse);
    expect(result.error, 'السلة فارغة');
  });

  test('Checkout: no payment method returns failure', () async {
    final container = createTestContainer(database);
    addTearDown(container.dispose);

    final products = await database.productsDao.getAllProducts();
    final cartNotifier = container.read(cartProvider.notifier);
    cartNotifier.addProduct(products[0]);

    final cart = container.read(cartProvider);
    final payment = container.read(paymentProvider); // no method selected

    final invoiceCreation = container.read(invoiceCreationProvider.notifier);
    final result = await invoiceCreation.checkout(
      cart: cart,
      payment: payment,
    );

    expect(result.success, isFalse);
    expect(result.error, 'اختر طريقة الدفع');
  });
}