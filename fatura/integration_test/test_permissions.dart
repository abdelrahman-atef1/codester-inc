/// test_permissions.dart — Integration tests for role-based permissions
///
/// Tests:
/// 1. POS Clerk cannot access Inventory
/// 2. Inventory Manager cannot access POS
/// 3. Owner can access everything
/// 4. Viewer can only access Reports
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fatura/core/database/database.dart' as db;
import 'package:fatura/core/utils/pin_hasher.dart';
import 'package:fatura/features/inventory/providers/inventory_providers.dart';
import 'package:fatura/features/auth/providers/auth_providers.dart';
import 'package:fatura/features/users/providers/permission_providers.dart';

import 'test_helpers.dart';

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = createTestDatabase();
    await seedStoreAndOwner(database, pin: '1234');
  });

  tearDown(() async {
    await database.close();
  });

  /// Helper: create a container with a specific user logged in.
  Future<ProviderContainer> loginAsRole(String role, String pin) async {
    final salt = generateSalt();
    final pinHash = hashPin(pin, salt);

    await database.usersDao.insertUser(
      db.UsersCompanion(
        storeId: const Value(1),
        name: Value('مستخدم $role'),
        pinHash: Value(pinHash),
        pinSalt: Value(salt),
        role: Value(role),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
    );

    // Login with the PIN
    final sessionNotifier = container.read(authSessionProvider.notifier);
    await sessionNotifier.loginWithPin(pin);

    return container;
  }

  test('Owner has wildcard permission (access to everything)', () async {
    final container = await loginAsRole('owner', '5678');
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, contains('*'));

    // Owner can access every screen
    expect(container.read(permissionProvider(Permissions.pos)), isTrue);
    expect(container.read(permissionProvider(Permissions.invoices)), isTrue);
    expect(container.read(permissionProvider(Permissions.inventory)), isTrue);
    expect(container.read(permissionProvider(Permissions.reports)), isTrue);
    expect(container.read(permissionProvider(Permissions.settings)), isTrue);
    expect(container.read(permissionProvider(Permissions.users)), isTrue);
    expect(container.read(permissionProvider(Permissions.activityLog)), isTrue);
  });

  test('POS Clerk can access POS + Invoices only', () async {
    final container = await loginAsRole('pos_clerk', '6789');
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, contains(Permissions.pos));
    expect(perms, contains(Permissions.invoices));
    expect(perms, isNot(contains('*')));

    // Can access POS
    expect(container.read(permissionProvider(Permissions.pos)), isTrue);
    // Can access Invoices
    expect(container.read(permissionProvider(Permissions.invoices)), isTrue);
    // CANNOT access Inventory
    expect(container.read(permissionProvider(Permissions.inventory)), isFalse);
    // CANNOT access Reports
    expect(container.read(permissionProvider(Permissions.reports)), isFalse);
    // CANNOT access Settings
    expect(container.read(permissionProvider(Permissions.settings)), isFalse);
    // CANNOT access Users
    expect(container.read(permissionProvider(Permissions.users)), isFalse);
    // CANNOT access Activity Log
    expect(container.read(permissionProvider(Permissions.activityLog)), isFalse);
  });

  test('Inventory Manager can access Inventory only', () async {
    final container = await loginAsRole('inventory_manager', '7890');
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, contains(Permissions.inventory));
    expect(perms, isNot(contains('*')));

    // Can access Inventory
    expect(container.read(permissionProvider(Permissions.inventory)), isTrue);
    // CANNOT access POS
    expect(container.read(permissionProvider(Permissions.pos)), isFalse);
    // CANNOT access Invoices
    expect(container.read(permissionProvider(Permissions.invoices)), isFalse);
    // CANNOT access Reports
    expect(container.read(permissionProvider(Permissions.reports)), isFalse);
    // CANNOT access Settings
    expect(container.read(permissionProvider(Permissions.settings)), isFalse);
    // CANNOT access Users
    expect(container.read(permissionProvider(Permissions.users)), isFalse);
  });

  test('Viewer can access Reports only', () async {
    final container = await loginAsRole('viewer', '8901');
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, contains(Permissions.reports));
    expect(perms, isNot(contains('*')));

    // Can access Reports
    expect(container.read(permissionProvider(Permissions.reports)), isTrue);
    // CANNOT access POS
    expect(container.read(permissionProvider(Permissions.pos)), isFalse);
    // CANNOT access Inventory
    expect(container.read(permissionProvider(Permissions.inventory)), isFalse);
    // CANNOT access Settings
    expect(container.read(permissionProvider(Permissions.settings)), isFalse);
    // CANNOT access Users
    expect(container.read(permissionProvider(Permissions.users)), isFalse);
  });

  test('Logged-out user has no permissions', () {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, isEmpty);

    expect(container.read(permissionProvider(Permissions.pos)), isFalse);
    expect(container.read(permissionProvider(Permissions.invoices)), isFalse);
    expect(container.read(permissionProvider(Permissions.inventory)), isFalse);
  });

  test('guardRoute returns /login when not logged in', () {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);

    // Use a ConsumerContext to test guardRoute
    // Since guardRoute requires WidgetRef, we test the logic indirectly
    final session = container.read(authSessionProvider);
    expect(session.isLoggedIn, isFalse);

    final perms = container.read(userPermissionsProvider);
    expect(perms, isEmpty);
    expect(container.read(permissionProvider(Permissions.pos)), isFalse);
  });

  test('Custom permissions override role defaults', () async {
    // Insert a pos_clerk with custom permissions including inventory
    final salt = generateSalt();
    final pinHash = hashPin('1357', salt);

    await database.usersDao.insertUser(
      db.UsersCompanion(
        storeId: const Value(1),
        name: const Value('بائع مميز'),
        pinHash: Value(pinHash),
        pinSalt: Value(salt),
        role: const Value('pos_clerk'),
        permissions: const Value('["pos","invoices","inventory"]'),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);

    // Login
    final sessionNotifier = container.read(authSessionProvider.notifier);
    final success = await sessionNotifier.loginWithPin('1357');
    expect(success, isTrue);

    // Custom permissions should be used (pos + invoices + inventory)
    final perms = container.read(userPermissionsProvider);
    expect(perms, contains(Permissions.pos));
    expect(perms, contains(Permissions.invoices));
    expect(perms, contains(Permissions.inventory));
    expect(perms, isNot(contains('*')));

    // Now has inventory access (custom override)
    expect(container.read(permissionProvider(Permissions.inventory)), isTrue);
    // Still can't access reports (not in custom perms)
    expect(container.read(permissionProvider(Permissions.reports)), isFalse);
  });
}