/// test_onboarding.dart — Widget tests for the onboarding wizard
///
/// Tests:
/// 1. Opening the app for the first time → onboarding wizard appears
/// 2. Entering store name → next
/// 3. Entering address + currency → next
/// 4. Entering PIN (4-6 digits) → save
/// 5. Verifies store was saved in DB
/// 6. Verifies user (owner) was saved in DB with PIN hash
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fatura/core/database/database.dart' as db;
import 'package:fatura/core/utils/pin_hasher.dart';
import 'package:fatura/features/inventory/providers/inventory_providers.dart';
import 'package:fatura/features/onboarding/presentation/screens/onboarding_screen.dart';

import 'helpers/test_helpers.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  ProviderScope buildHarness() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Center(child: Text('Login'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('Onboarding wizard appears on first launch', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Welcome page should be visible
    expect(find.text('مرحباً بك في فاتورة'), findsOneWidget);
    // Skip button exists
    expect(find.text('تخطٍ'), findsOneWidget);
    // Next button exists
    expect(find.text('التالي'), findsOneWidget);
  });

  testWidgets(
      'Complete onboarding flow: store info → type → PIN → saved in DB',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // ─── Page 0: Welcome → tap "التالي" ───
    expect(find.text('مرحباً بك في فاتورة'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    // ─── Page 1: Store Info ───
    expect(find.text('بيانات المتجر'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'متجر الاختبار');
    await tester.enterText(find.byType(TextField).at(1), 'شارع الاختبار 123');
    await tester.enterText(find.byType(TextField).at(2), '01000000000');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    // ─── Page 2: Store Type ───
    expect(find.text('نوع المتجر'), findsOneWidget);
    await tester.tap(find.text('كشك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    // ─── Page 3: PIN Setup ───
    expect(find.text('ادخل الرمز السري'), findsOneWidget);

    // Enter PIN "1234" via the on-screen numpad
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit).last);
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Tap "حفظ ومتابعة"
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();

    // ─── Verify DB state ───

    // 1. Store was saved
    final stores = await database.storesDao.getAllStores();
    expect(stores.length, 1, reason: 'One store should have been saved');
    expect(stores.first.name, 'متجر الاختبار');
    expect(stores.first.type, 'كشك');
    expect(stores.first.address, 'شارع الاختبار 123');

    // 2. Owner user was saved with PIN hash
    final users = await database.usersDao.getAllUsers();
    expect(users.length, 1, reason: 'One owner user should have been saved');
    expect(users.first.role, 'owner');
    expect(users.first.name, 'المالك');
    expect(users.first.pinHash, isNotEmpty);
    expect(users.first.pinSalt, isNotEmpty);

    // 3. PIN hash matches
    final pinValid =
        verifyPin('1234', users.first.pinSalt, users.first.pinHash);
    expect(pinValid, isTrue,
        reason: 'PIN "1234" should verify against stored hash');

    // 4. PIN is NOT stored in plaintext
    expect(users.first.pinHash, isNot('1234'));
    expect(users.first.pinHash.length, 64,
        reason: 'SHA-256 hex should be 64 chars');
  });

  testWidgets('PIN too short (< 4 digits) shows error', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Navigate to PIN page (page 3)
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }

    expect(find.text('ادخل الرمز السري'), findsOneWidget);

    // Enter only 3 digits
    for (final digit in ['1', '2', '3']) {
      await tester.tap(find.text(digit).last);
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Tap save
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();

    // Should show error
    expect(find.text('الرمز يجب أن يكون 4-6 أرقام'), findsOneWidget);

    // Nothing saved to DB
    final stores = await database.storesDao.getAllStores();
    expect(stores, isEmpty,
        reason: 'No store should be saved with invalid PIN');
  });

  testWidgets('Skip button navigates away without saving', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('تخطٍ'));
    await tester.pumpAndSettle();

    // Nothing saved
    final stores = await database.storesDao.getAllStores();
    expect(stores, isEmpty);
  });
}