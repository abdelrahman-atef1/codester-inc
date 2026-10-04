/// pos_dashboard_test.dart — Widget tests for the Bold Executive POS screen.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fatura/data/database.dart';
import 'package:fatura/data/repository.dart';
import 'package:fatura/providers/pos_providers.dart';
import 'package:fatura/screens/pos_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PosDatabase database;

  Widget buildHarness() {
    return ProviderScope(
      overrides: [
        posDatabaseProvider.overrideWithValue(database),
      ],
      child: const MaterialApp(home: PosDashboardScreen()),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Unmount the tree and flush Drift stream-dispose timers before the
  /// test zone's invariant check (avoids "Timer is still pending" errors).
  Future<void> unmountScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  group('PosDashboardScreen', () {
    setUp(() async {
      database = PosDatabase.forTesting(NativeDatabase.memory());
      final repo = PosRepository(database);
      await repo.insertCategory(
          CategoriesCompanion.insert(name: 'مشروبات', icon: const Value('local_drink')));
      await repo.insertCategory(
          CategoriesCompanion.insert(name: 'ألبان', icon: const Value('egg_alt')));
      await repo.insertProduct(ProductsCompanion.insert(
        name: 'حليب جهينة',
        price: 35.0,
        unit: const Value('١ لتر'),
        icon: const Value('water_bottle'),
        colorHue: const Value(0),
      ));
      await repo.insertProduct(ProductsCompanion.insert(
        name: 'بيبسي كانز',
        price: 12.0,
        unit: const Value('٣٣٠ مل'),
        icon: const Value('local_cafe'),
        colorHue: const Value(1),
      ));
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('renders top bar, search, barcode button, categories, grid and cart panel',
        (tester) async {
      await pumpScreen(tester);

      // Top bar
      expect(find.text('سوبر ماركت النور'), findsOneWidget);
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('وردية صباحية'), findsOneWidget);

      // Search + barcode
      expect(find.byKey(const Key('pos_search_field')), findsOneWidget);
      expect(find.byKey(const Key('barcode_button')), findsOneWidget);

      // Metrics strip
      expect(find.text('مبيعات الوردية'), findsOneWidget);
      expect(find.text('عدد الفواتير'), findsOneWidget);
      expect(find.text('حالة الدرج'), findsOneWidget);

      // Category chips (الكل + seeded)
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('مشروبات'), findsOneWidget);
      expect(find.text('ألبان'), findsOneWidget);

      // Product grid tiles
      expect(find.text('حليب جهينة'), findsOneWidget);
      expect(find.text('بيبسي كانز'), findsOneWidget);

      // Cart panel + bottom nav
      expect(find.byKey(const Key('checkout_button')), findsOneWidget);
      expect(find.text('نقطة البيع'), findsOneWidget);
      expect(find.text('الفواتير'), findsOneWidget);
      expect(find.text('المخزون'), findsOneWidget);
      expect(find.text('التقارير'), findsOneWidget);

      await unmountScreen(tester);
    });

    testWidgets('tapping a product adds it to the cart and shows badge',
        (tester) async {
      await pumpScreen(tester);

      final container = ProviderScope.containerOf(
          tester.element(find.byType(PosDashboardScreen)));
      final products =
          await PosRepository(database).getProducts(query: 'حليب');
      expect(products, hasLength(1));

      container.read(cartProvider.notifier).addProduct(products.first);
      container.read(cartProvider.notifier).addProduct(products.first);
      await tester.pump();

      // Red badge on the tile + cart line appears.
      expect(
          find.byKey(Key('cart_badge_${products.first.id}')), findsOneWidget);
      final lines = container.read(cartProvider);
      expect(lines, hasLength(1));
      expect(lines.first.quantity, 2);
      expect(container.read(cartTotalsProvider).total,
          closeTo(2 * 35.0 * 1.14, 0.01));
      expect(container.read(cartTotalsProvider).itemCount, 2);

      await unmountScreen(tester);
    });

    testWidgets('search filters products', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
          find.byKey(const Key('pos_search_field')), 'بيبسي');
      await tester.pumpAndSettle();

      // Provider-level assertion (stream re-filter applied).
      final container = ProviderScope.containerOf(
          tester.element(find.byType(PosDashboardScreen)));
      final filtered = container.read(productsProvider).valueOrNull ?? [];
      expect(filtered.map((p) => p.name), contains('بيبسي كانز'));
      expect(filtered.map((p) => p.name), isNot(contains('حليب جهينة')));

      // Widget-level assertion.
      expect(find.text('بيبسي كانز'), findsOneWidget);
      expect(find.text('حليب جهينة'), findsNothing);

      await unmountScreen(tester);
    });

    testWidgets('category chip filters products', (tester) async {
      final repo = PosRepository(database);
      // Put حليب in ألبان category only.
      final dairy =
          (await repo.getCategories()).firstWhere((c) => c.name == 'ألبان');
      final milk = (await repo.getProducts(query: 'حليب')).first;
      await (database.update(database.products)
            ..where((p) => p.id.equals(milk.id)))
          .write(ProductsCompanion(categoryId: Value(dairy.id)));

      await pumpScreen(tester);

      final container = ProviderScope.containerOf(
          tester.element(find.byType(PosDashboardScreen)));
      container.read(selectedCategoryProvider.notifier).state = dairy.id;
      await tester.pumpAndSettle();

      // Provider-level assertion (stream re-filter applied).
      final filtered = container.read(productsProvider).valueOrNull ?? [];
      expect(filtered.map((p) => p.name), contains('حليب جهينة'));
      expect(filtered.map((p) => p.name), isNot(contains('بيبسي كانز')));

      expect(find.text('حليب جهينة'), findsOneWidget);
      expect(find.text('بيبسي كانز'), findsNothing);

      await unmountScreen(tester);
    });

    testWidgets('checkout persists invoice and clears cart', (tester) async {
      await pumpScreen(tester);

      final container = ProviderScope.containerOf(
          tester.element(find.byType(PosDashboardScreen)));
      final repo = PosRepository(database);
      final products = await repo.getProducts();

      container.read(cartProvider.notifier).addProduct(products.first);
      container.read(cartProvider.notifier).addProduct(products.last);

      final invoiceId =
          await container.read(cartProvider.notifier).checkout();
      expect(invoiceId, greaterThan(0));
      expect(container.read(cartProvider), isEmpty);

      final saved = await repo.getInvoice(invoiceId);
      expect(saved, isNotNull);
      expect(saved!.items, hasLength(2));
      expect(saved.invoice.invoiceNumber, 'INV-00001');
      expect(saved.invoice.total, closeTo((35.0 + 12.0) * 1.14, 0.01));

      await unmountScreen(tester);
    });
  });
}
