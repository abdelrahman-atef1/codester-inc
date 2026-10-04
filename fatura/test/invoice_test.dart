/// invoice_test.dart — Widget tests for the Bold Executive invoice screen.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fatura/data/database.dart';
import 'package:fatura/data/repository.dart';
import 'package:fatura/providers/pos_providers.dart';
import 'package:fatura/screens/invoice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PosDatabase database;

  setUp(() {
    database = PosDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildHarness(Widget screen) {
    return ProviderScope(
      overrides: [
        posDatabaseProvider.overrideWithValue(database),
      ],
      child: MaterialApp(home: screen),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness(screen));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Unmount the tree and flush pending timers before zone invariant check.
  Future<void> unmountScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  group('InvoiceScreen', () {
    testWidgets('renders header, banner, receipt card, and action buttons',
        (tester) async {
      // Seed one product + one persisted invoice (INV-00248).
      final repo = PosRepository(database);
      final productId = await repo.insertProduct(ProductsCompanion.insert(
        name: 'حليب جهينة ١ لتر',
        price: 35.0,
        unit: const Value('كامل الدسم'),
      ));
      final product = await repo.getProductById(productId);
      final invoiceId = await repo.createInvoice(
        invoiceNumber: 'INV-00248',
        lines: [CartLine(product: product!, quantity: 2)],
        discount: 10.0,
      );

      await pumpScreen(tester, InvoiceScreen(invoiceId: invoiceId));

      // Top bar: invoice number + paid badge + back + more
      expect(find.textContaining('فاتورة INV-00248'), findsOneWidget);
      expect(find.text('مدفوعة'), findsOneWidget);
      expect(find.byKey(const Key('invoice_back_button')), findsOneWidget);
      expect(find.byKey(const Key('invoice_more_button')), findsOneWidget);

      // Success banner
      expect(find.text('تم تسجيل المعاملة بنجاح'), findsOneWidget);
      expect(find.textContaining('ZATCA'), findsOneWidget);

      // Store header on the receipt
      expect(find.text('سوبر ماركت النور'), findsOneWidget);
      expect(find.text('١٢ شارع التحرير، الدقي، الجيزة'), findsOneWidget);
      expect(find.text('هاتف: ٠١٠١٢٣٤٥٦٧٨'), findsOneWidget);
      expect(find.text('ن'), findsOneWidget); // red logo stamp

      // Meta grid
      expect(find.text('رقم الفاتورة'), findsOneWidget);
      expect(find.text('INV-00248'), findsAtLeastNWidgets(1));
      expect(find.text('العميل'), findsOneWidget);
      expect(find.text('عميل نقدي'), findsOneWidget);
      expect(find.text('طريقة الدفع'), findsOneWidget);
      expect(find.text('نقداً'), findsOneWidget);

      // Items table
      expect(find.text('الصنف'), findsOneWidget);
      expect(find.text('الكمية'), findsOneWidget);
      expect(find.text('السعر'), findsOneWidget);
      expect(find.text('الإجمالي'), findsOneWidget);
      expect(find.text('حليب جهينة ١ لتر'), findsOneWidget);
      expect(find.text('كامل الدسم'), findsOneWidget);

      // Totals breakdown
      expect(find.text('المجموع الفرعي'), findsOneWidget);
      expect(find.text('ضريبة القيمة المضافة (١٤٪)'), findsOneWidget);
      expect(find.text('خصم ترويجي'), findsOneWidget);

      // Grand total bar: 70.00 subtotal + 9.80 tax − 10.00 discount = 69.80
      expect(find.byKey(const Key('grand_total_bar')), findsOneWidget);
      expect(find.text('الإجمالي النهائي'), findsOneWidget);
      expect(find.textContaining('69.80'), findsOneWidget);

      // QR + thank-you footer
      expect(find.byKey(const Key('invoice_qr')), findsOneWidget);
      expect(find.text('شكراً لتعاملكم معنا'), findsOneWidget);

      // Support card (may need scroll on small surfaces)
      await tester.ensureVisible(find.text('الإبلاغ عن خطأ'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('هل تواجه مشكلة بالفاتورة؟'), findsOneWidget);
      expect(find.text('الإبلاغ عن خطأ'), findsOneWidget);

      // Bottom actions: share + print
      expect(find.byKey(const Key('share_button')), findsOneWidget);
      expect(find.byKey(const Key('print_button')), findsOneWidget);
      expect(find.text('مشاركة'), findsOneWidget);
      expect(find.text('طباعة الإيصال'), findsOneWidget);

      await unmountScreen(tester);
    });

    testWidgets('renders static demo invoice when no id is provided',
        (tester) async {
      await pumpScreen(tester, const InvoiceScreen());

      // Demo design rows from the Stitch HTML.
      expect(find.textContaining('فاتورة #INV-00248'), findsOneWidget);
      expect(find.text('حليب جهينة ١ لتر'), findsOneWidget);
      expect(find.text('أرز الضحى ١ كجم'), findsOneWidget);
      expect(find.text('شاي العروسة ٢٥٠ جم'), findsOneWidget);
      expect(find.text('بيبسي ٣٣٠ مل'), findsOneWidget);
      // Design total: 252.50 + 35.35 − 10.00
      expect(find.textContaining('277.85'), findsOneWidget);

      await unmountScreen(tester);
    });
  });
}
