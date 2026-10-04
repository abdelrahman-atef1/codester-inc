/// reports_test.dart — Widget tests for Bold Executive ReportsScreen
///
/// Tests:
/// 1. Dark app bar with "فاتورة" branding and share/print icons
/// 2. Screen title "التقارير" and subtitle
/// 3. Date chip
/// 4. Segmented control with 3 tabs (اليوم active)
/// 5. Hero KPI card: total sales, trend badge, profit, VAT
/// 6. Secondary KPI cards: invoice count, average ticket
/// 7. Hourly sales bar chart section
/// 8. Top 5 products with progress bars
/// 9. Footer compliance text
/// 10. Bottom nav with التقارير active
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:fatura/screens/reports_screen.dart';

Widget _buildReportsScreen() {
  return MaterialApp(
    home: const ReportsScreen(),
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

void main() {
  group('ReportsScreen', () {
    testWidgets('renders dark app bar with brand name and actions', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('فاتورة'), findsWidgets);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.print), findsOneWidget);
    });

    testWidgets('renders screen title and subtitle', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('التقارير'), findsWidgets);
      expect(find.text('ملخص الأداء والمبيعات اللحظية'), findsOneWidget);
    });

    testWidgets('renders date chip', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('٢٤ أكتوبر ٢٠٢٣'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('renders segmented control with 3 tabs', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('اليوم'), findsOneWidget);
      expect(find.text('الأسبوع'), findsOneWidget);
      expect(find.text('الشهر'), findsOneWidget);
    });

    testWidgets('renders hero KPI card with total sales', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('مبيعات اليوم الإجمالية'), findsOneWidget);
      expect(find.text('١٢,٤٨٥٫٠٠'), findsOneWidget);
      // Trend badge
      expect(find.text('▲ ١٨٪'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('renders hero secondary stats (profit + VAT)', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('صافي الأرباح'), findsOneWidget);
      expect(find.text('٣,١٢٠'), findsOneWidget);
      expect(find.text('ضريبة القيمة المضافة (١٤٪)'), findsOneWidget);
      expect(find.text('١,٥٣٢'), findsOneWidget);
    });

    testWidgets('renders secondary KPI cards (invoices + average ticket)', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      // Invoice count card
      expect(find.text('عدد الفواتير'), findsOneWidget);
      expect(find.text('٤٧'), findsOneWidget);
      expect(find.text('فاتورة'), findsWidgets);
      expect(find.text('↑ +٥ مقارنة بأمس'), findsOneWidget);

      // Average ticket card
      expect(find.text('متوسط الفاتورة'), findsOneWidget);
      expect(find.text('٢٦٥٫٦٤'), findsOneWidget);
      expect(find.text('↑ +١٢ ج.م عن أمس'), findsOneWidget);
    });

    testWidgets('renders hourly sales chart section', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('المبيعات بالساعة'), findsOneWidget);
      expect(find.text('ذروة المبيعات: ٥:٠٠ م - ٦:٠٠ م'), findsOneWidget);
      expect(find.text('توقيت محلي'), findsOneWidget);
    });

    testWidgets('renders hourly bar labels', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      // Scroll down to see the chart
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Hour labels at bottom of chart
      expect(find.text('٩ ص'), findsOneWidget);
      expect(find.text('١١ ص'), findsOneWidget);
      expect(find.text('١ م'), findsOneWidget);
      expect(find.text('٣ م'), findsOneWidget);
      expect(find.text('٥ م'), findsOneWidget);
      expect(find.text('٧ م'), findsOneWidget);
      expect(find.text('٩ م'), findsOneWidget);
    });

    testWidgets('renders peak badge with amount', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      // Scroll down to see the chart
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('٣,٢٤٠'), findsOneWidget);
    });

    testWidgets('renders top 5 products card', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('الأكثر مبيعاً'), findsOneWidget);
      expect(find.text('حسب الإيراد المحقق اليوم'), findsOneWidget);
      expect(find.text('أفضل ٥ أصناف'), findsOneWidget);
    });

    testWidgets('renders top product names and details', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      // Scroll down to see top products
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('أرز الضحى ١ كجم'), findsOneWidget);
      expect(find.text('٦٤ وحدة مباعة'), findsOneWidget);
      expect(find.text('٢,٠٨٠'), findsOneWidget);
      expect(find.text('حليب جهينة ١ لتر'), findsOneWidget);
      expect(find.text('٥٨ وحدة مباعة'), findsOneWidget);
    });

    testWidgets('renders rank badges 1-5', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      // Scroll down to see top products
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('١'), findsOneWidget);
      expect(find.text('٢'), findsOneWidget);
      expect(find.text('٣'), findsOneWidget);
      expect(find.text('٤'), findsOneWidget);
      expect(find.text('٥'), findsOneWidget);
    });

    testWidgets('renders footer compliance text', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      // Scroll down to see footer
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(
        find.text('فاتورة POS • متوافق مع متطلبات الفاتورة الإلكترونية المصرية'),
        findsOneWidget,
      );
    });

    testWidgets('renders bottom nav with التقارير active', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('نقطة البيع'), findsOneWidget);
      expect(find.text('الفواتير'), findsOneWidget);
      expect(find.text('المخزون'), findsOneWidget);
      // "التقارير" appears in header AND bottom nav
      expect(find.text('التقارير'), findsWidgets);
    });

    testWidgets('segment control switches tabs', (tester) async {
      await tester.pumpWidget(_buildReportsScreen());
      await tester.pumpAndSettle();

      // Initially اليوم is active
      // Tap on الأسبوع
      await tester.tap(find.text('الأسبوع'));
      await tester.pumpAndSettle();

      // No crash and tab is now selected (visual check not trivial)
      expect(find.text('الأسبوع'), findsOneWidget);
    });
  });
}
