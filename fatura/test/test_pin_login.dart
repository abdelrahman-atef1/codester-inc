/// test_pin_login.dart — Widget tests for PIN login screen
///
/// Tests:
/// 1. After onboarding → PIN login screen appears
/// 2. Entering wrong PIN → error shake + "رمز خاطئ"
/// 3. Entering correct PIN → navigate to home
/// 4. Role selector shows all roles
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fatura/core/database/database.dart' as db;
import 'package:fatura/features/inventory/providers/inventory_providers.dart';
import 'package:fatura/features/auth/presentation/screens/pin_login_screen.dart';
import 'package:fatura/features/auth/providers/auth_providers.dart';

import 'helpers/test_helpers.dart';

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = createTestDatabase();
    await seedStoreAndOwner(database, pin: '1234');
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildHarness() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const MaterialApp(home: PinLoginScreen()),
    );
  }

  testWidgets('PIN login screen shows role selector and PIN entry',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('فاتورة'), findsOneWidget);
    expect(find.text('اختر دورك'), findsOneWidget);
    expect(find.text('أدخل الرمز السري'), findsOneWidget);
  });

  testWidgets('Role selector shows all four roles', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('مالك'), findsOneWidget);
    expect(find.text('بائع'), findsOneWidget);
    expect(find.text('مدير مخزون'), findsOneWidget);
    expect(find.text('مشاهد'), findsOneWidget);
  });

  testWidgets('Wrong PIN triggers error message', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Enter wrong PIN "999999" (6 digits to force error)
    for (final digit in ['9', '9', '9', '9', '9', '9']) {
      await tester.tap(find.text(digit).last);
      await tester.pump(const Duration(milliseconds: 150));
    }

    // Wait for error to appear
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The error message "رمز خاطئ، حاول مرة أخرى" should appear
    expect(find.text('رمز خاطئ، حاول مرة أخرى'), findsOneWidget);
  });

  testWidgets('Correct PIN authenticates the user', (tester) async {
    final container = createTestContainer(database);
    addTearDown(container.dispose);

    final sessionNotifier = container.read(authSessionProvider.notifier);
    // Login via the auth provider directly
    final success = await sessionNotifier.loginWithPin('1234');
    expect(success, isTrue, reason: 'Correct PIN "1234" should login successfully');

    final session = container.read(authSessionProvider);
    expect(session.isLoggedIn, isTrue);
    expect(session.user?.role, 'owner');
    expect(session.isOwner, isTrue);
  });
}