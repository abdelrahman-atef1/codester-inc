/// test_pos.dart — Tests for POS (Point of Sale) cart, payment, and checkout
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

import 'helpers/test_helpers.dart';

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = createTestDatabase();
    await seedStoreAndOwner(database, pin: '1234');
    await seedProduct(database,
        name: 'ماء معدني 0.5 لتر', price: 5.0, quantity: 50, barcode: '6001111111111');
    await seedProduct(database,
        name: 'شاي أخضر كيس', price: 12.50, quantity: 30, barcode: '6002222222222');
    await seedProduct(database,
        name: 'بسكويت شوكولاتة', price: 8.0, quantity: 100, barcode: '6003333333333');
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

  testWidgets('POS screen shows product search and title', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('بيع سريع'), findsAny);
    expect(find.byType(TextField), findsAny);

    // Clear widget tree early so Drift stream timers fire before _verifyInvariants
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Products appear in POS grid', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ماء معدني 0.5 لتر'), findsAny);
    expect(find.text('شاي أخضر كيس'), findsAny);
    expect(find.text('بسكويت شوكولاتة'), findsAny);

    // Clear widget tree early so Drift stream timers fire before _verifyInvariants
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  });

  // ─── Cart + payment unit tests ───

  test('CartState: subtotal, tax, and total calculations are correct',
      () async {
    final products = await database.productsDao.getAllProducts();
    final product1 = products[0]; // 5.0 EGP
    final product2 = products[1]; // 12.50 EGP

    final cart = CartState(
      items: [
        CartItem(product: product1, quantity: 2), // 5.0 × 2 = 10.0
        CartItem(product: product2, quantity: 3), // 12.50 × 3 = 37.5
      ],
      taxEnabled: true,
      taxRate: 14.0,
    );

    expect(cart.subtotal, 47.5);
    expect(cart.taxAmount, closeTo(6.65, 0.001));
    expect(cart.total, closeTo(54.15, 0.001));
    expect(cart.itemCount, 5);
    expect(cart.uniqueCount, 2);
  });

  test('CartState: no tax when taxEnabled is false', () {
    const cart = CartState(items: [], taxEnabled: false, taxRate: 14.0);
    expect(cart.taxAmount, 0);
    expect(cart.total, cart.subtotal);
  });

  test('PaymentState: change calculation for cash', () {
    const payment =
        PaymentState(method: PaymentMethod.cash, amountPaid: 100.0);
    final change = payment.calculateChange(54.15);
    expect(change, closeTo(45.85, 0.001));
  });

  test('PaymentState: no change when amountPaid < total', () {
    const payment =
        PaymentState(method: PaymentMethod.cash, amountPaid: 30.0);
    expect(payment.calculateChange(54.15), 0);
  });

  test('PaymentState: no change for non-cash methods', () {
    const payment = PaymentState(method: PaymentMethod.card);
    expect(payment.calculateChange(54.15), 0);
  });

  // ─── Checkout integration test ───

  test('Checkout: creates invoice, decrements inventory, logs activity',
      () async {
    final container = createTestContainer(database);
    addTearDown(container.dispose);

    final products = await database.productsDao.getAllProducts();
    final product1 = products[0]; // 5.0 EGP, qty 50
    final product2 = products[1]; // 12.50 EGP, qty 30

    // Build cart
    final cartNotifier = container.read(cartProvider.notifier);
    cartNotifier.addProduct(product1);
    cartNotifier.addProduct(product1); // qty 2
    cartNotifier.addProduct(product2); // qty 1
    cartNotifier.updateTaxSettings(enabled: true, rate: 14.0);

    // Select payment
    final paymentNotifier = container.read(paymentProvider.notifier);
    paymentNotifier.selectMethod(PaymentMethod.cash);
    paymentNotifier.setAmountPaid(100.0);

    // Get owner
    final users = await database.usersDao.getAllUsers();
    final owner = users.first;

    // Checkout
    final cart = container.read(cartProvider);
    final payment = container.read(paymentProvider);

    final invoiceCreation = container.read(invoiceCreationProvider.notifier);
    final result = await invoiceCreation.checkout(
      cart: cart,
      payment: payment,
      userId: owner.id,
      storeId: owner.storeId,
    );

    // ─── Verify ───
    expect(result.success, isTrue, reason: result.error ?? 'Checkout should succeed');
    expect(result.invoiceNumber, isNotNull);
    expect(result.total, closeTo((5.0 * 2 + 12.50) * 1.14, 0.01));

    // Invoice in DB
    final invoices = await database.invoicesDao.getAllInvoices();
    expect(invoices.length, 1);
    expect(invoices.first.invoiceNumber, result.invoiceNumber);
    expect(invoices.first.status, 'completed');
    expect(invoices.first.subtotal, closeTo(5.0 * 2 + 12.50, 0.001));
    expect(invoices.first.tax, closeTo((5.0 * 2 + 12.50) * 0.14, 0.001));
    expect(invoices.first.total, closeTo((5.0 * 2 + 12.50) * 1.14, 0.01));
    expect(invoices.first.paymentMethod, 'cash');

    // Invoice items in DB
    final invoiceItems =
        await database.invoiceItemsDao.getItemsByInvoice(invoices.first.id);
    expect(invoiceItems.length, 2);

    // Product quantities decremented
    final p1After = await database.productsDao.getProductById(product1.id);
    final p2After = await database.productsDao.getProductById(product2.id);
    expect(p1After!.quantity, 48, reason: '50 → 48 (decremented by 2)');
    expect(p2After!.quantity, 29, reason: '30 → 29 (decremented by 1)');

    // Activity log
    final logs = await database.activityLogDao.getAllLogs();
    final saleLog = logs.where((l) => l.action == 'sale').toList();
    expect(saleLog.length, 1);
    expect(saleLog.first.entityType, 'invoice');
  });

  test('Checkout: empty cart returns failure', () async {
    final container = createTestContainer(database);
    addTearDown(container.dispose);

    final cart = container.read(cartProvider);
    final payment = container.read(paymentProvider);

    final invoiceCreation = container.read(invoiceCreationProvider.notifier);
    final result = await invoiceCreation.checkout(cart: cart, payment: payment);

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
    final payment = container.read(paymentProvider);

    final invoiceCreation = container.read(invoiceCreationProvider.notifier);
    final result = await invoiceCreation.checkout(cart: cart, payment: payment);

    expect(result.success, isFalse);
    expect(result.error, 'اختر طريقة الدفع');
  });

  test('CartNotifier: add, increment, decrement, remove, clear', () async {
    final products = await database.productsDao.getAllProducts();
    final product1 = products[0];

    final container = createTestContainer(database);
    addTearDown(container.dispose);

    final cartNotifier = container.read(cartProvider.notifier);

    // Add
    cartNotifier.addProduct(product1);
    expect(container.read(cartProvider).itemCount, 1);
    expect(container.read(cartProvider).uniqueCount, 1);

    // Increment (add same product again)
    cartNotifier.addProduct(product1);
    expect(container.read(cartProvider).itemCount, 2);

    // Explicit increment
    cartNotifier.incrementQuantity(product1.id);
    expect(container.read(cartProvider).itemCount, 3);

    // Decrement
    cartNotifier.decrementQuantity(product1.id);
    expect(container.read(cartProvider).itemCount, 2);

    // Set quantity
    cartNotifier.setQuantity(product1.id, 5);
    expect(container.read(cartProvider).itemCount, 5);

    // Remove
    cartNotifier.removeItem(product1.id);
    expect(container.read(cartProvider).isEmpty, isTrue);

    // Add again then clear
    cartNotifier.addProduct(product1);
    cartNotifier.clear();
    expect(container.read(cartProvider).isEmpty, isTrue);
  });
}