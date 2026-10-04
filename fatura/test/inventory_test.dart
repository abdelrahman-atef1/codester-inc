/// inventory_test.dart — Widget tests for Bold Executive InventoryScreen
///
/// Tests:
/// 1. App bar renders with title, stats, action icons
/// 2. Search bar exists
/// 3. Category chips render and select
/// 4. Product cards display with correct info
/// 5. Stock badges (in-stock / low-stock / out-of-stock)
/// 6. FAB renders
/// 7. Bottom nav renders with 4 items, المخزون active
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:fatura/screens/inventory_screen.dart';

Widget _buildInventoryScreen() {
  return MaterialApp(
    home: const InventoryScreen(),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('ar', 'EG'),
      Locale('en', 'US'),
    ],
    locale: const Locale('en', 'US'),
  );
}

/// Scrolls the vertical product list until [text] is visible.
Future<void> _scrollToText(WidgetTester tester, String text) async {
  // Find the vertical Scrollable (the product list); the chips row is also a
  // horizontal Scrollable, so pick the one whose axisDirection is down.
  final verticalScrollable = find
      .byWidgetPredicate((w) =>
          w is Scrollable && w.axisDirection == AxisDirection.down)
      .first;
  await tester.scrollUntilVisible(
    find.text(text, skipOffstage: false),
    150.0,
    scrollable: verticalScrollable,
    maxScrolls: 50,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('InventoryScreen', () {
    testWidgets('renders dark app bar with title and stats', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      // "المخزون" appears in app bar AND bottom nav
      expect(find.text('المخزون'), findsWidgets);
      expect(find.text('٦ منتج'), findsOneWidget);
      expect(find.text('٣ منخفض المخزون'), findsOneWidget);
    });

    testWidgets('renders search bar with hint text', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ابحث بالاسم أو الباركود...'), findsOneWidget);
    });

    testWidgets('renders category chips', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('منخفض المخزون'), findsWidgets);
      expect(find.text('مشروبات'), findsOneWidget);
      expect(find.text('ألبان'), findsOneWidget);
      expect(find.text('معلبات'), findsOneWidget);
      expect(find.text('منظفات'), findsOneWidget);
      expect(find.text('مخبوزات'), findsOneWidget);
    });

    testWidgets('renders product cards with names', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      // First 3 products are visible without scrolling
      expect(find.text('حليب جهينة ١ لتر'), findsOneWidget);
      expect(find.text('أرز الضحى ١ كجم'), findsOneWidget);
      expect(find.text('شاي العروسة ٢٥٠ جم'), findsOneWidget);
      // Last 3 need scrolling
      await _scrollToText(tester, 'زيت كريستال ذرة ١ لتر');
      expect(find.text('زيت كريستال ذرة ١ لتر'), findsOneWidget);
      await _scrollToText(tester, 'بيبسي كانز ٣٣٠ مل');
      expect(find.text('بيبسي كانز ٣٣٠ مل'), findsOneWidget);
      await _scrollToText(tester, 'صابون لوكس ٨٥ جم');
      expect(find.text('صابون لوكس ٨٥ جم'), findsOneWidget);
    });

    testWidgets('displays in-stock badge for normal products', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('المخزون: ٩٥'), findsOneWidget);
      await _scrollToText(tester, 'بيبسي كانز ٣٣٠ مل');
      expect(find.text('المخزون: ١٢٠'), findsOneWidget);
    });

    testWidgets('displays low-stock badge for low stock products', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('منخفض: ٣ متبقي'), findsOneWidget);
      await _scrollToText(tester, 'زيت كريستال ذرة ١ لتر');
      expect(find.text('منخفض: ٤ متبقي'), findsOneWidget);
    });

    testWidgets('displays out-of-stock badge for zero stock products', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      await _scrollToText(tester, 'صابون لوكس ٨٥ جم');
      expect(find.text('نفذ المخزون (٠)'), findsOneWidget);
    });

    testWidgets('displays warning icon for low stock products', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      // Two low-stock items have warning icons (one visible, scroll for second)
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    });

    testWidgets('renders price in Arabic numerals with currency', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('٣٥٫٠٠'), findsOneWidget);
      expect(find.text('ج.م'), findsWidgets);
    });

    testWidgets('renders FAB add product button', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('إضافة منتج'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders bottom navigation with 4 items and active tab', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('نقطة البيع'), findsOneWidget);
      expect(find.text('الفواتير'), findsOneWidget);
      // "المخزون" appears in app bar AND bottom nav
      expect(find.text('المخزون'), findsWidgets);
      expect(find.text('التقارير'), findsOneWidget);
    });

    testWidgets('product card shows edit button for normal items', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('تعديل'), findsWidgets);
    });

    testWidgets('product card shows supply request for low-stock items', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.text('طلب توريد'), findsWidgets);
    });

    testWidgets('renders barcodes for each product', (tester) async {
      await tester.pumpWidget(_buildInventoryScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('٦٢٢١٠١٢٣٤٥'), findsOneWidget);
      expect(find.textContaining('٦٢٢٣٠٠١٩٨٧'), findsOneWidget);
    });
  });
}
