/// test_permissions.dart — Tests for role-based permissions
///
/// Tests:
/// 1. POS Clerk cannot access Inventory
/// 2. Inventory Manager cannot access POS
/// 3. Owner can access everything
/// 4. Viewer can access Reports only
/// 5. Custom permissions override role defaults
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fatura/core/database/database.dart' as db;
import 'package:fatura/core/utils/pin_hasher.dart';
import 'package:fatura/features/inventory/providers/inventory_providers.dart';
import 'package:fatura/features/auth/providers/auth_providers.dart';
import 'package:fatura/features/users/providers/permission_providers.dart';

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

  /// Helper: create a container with a user logged in under a specific role.
  Future<ProviderContainer> loginAsRole(String role, String pin) async {
    final salt = generateSalt();
    final pinHash = hashPin(pin, salt);

    await database.usersDao.insertUser(
      UsersCompanion(
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

    final sessionNotifier = container.read(authSessionProvider.notifier);
    await sessionNotifier.loginWithPin(pin);

    return container;
  }

  test('Owner has wildcard permission (access to everything)', () async {
    final container = await loginAsRole('owner', '5678');
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, contains('*'));

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

    expect(container.read(permissionProvider(Permissions.pos)), isTrue);
    expect(container.read(permissionProvider(Permissions.invoices)), isTrue);
    // CANNOT access these
    expect(container.read(permissionProvider(Permissions.inventory)), isFalse,
        reason: 'POS Clerk should NOT access Inventory');
    expect(container.read(permissionProvider(Permissions.reports)), isFalse,
        reason: 'POS Clerk should NOT access Reports');
    expect(container.read(permissionProvider(Permissions.settings)), isFalse);
    expect(container.read(permissionProvider(Permissions.users)), isFalse);
    expect(container.read(permissionProvider(Permissions.activityLog)), isFalse);
  });

  test('Inventory Manager can access Inventory only', () async {
    final container = await loginAsRole('inventory_manager', '7890');
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, contains(Permissions.inventory));
    expect(perms, isNot(contains('*')));

    expect(container.read(permissionProvider(Permissions.inventory)), isTrue);
    // CANNOT access these
    expect(container.read(permissionProvider(Permissions.pos)), isFalse,
        reason: 'Inventory Manager should NOT access POS');
    expect(container.read(permissionProvider(Permissions.invoices)), isFalse);
    expect(container.read(permissionProvider(Permissions.reports)), isFalse);
    expect(container.read(permissionProvider(Permissions.settings)), isFalse);
    expect(container.read(permissionProvider(Permissions.users)), isFalse);
  });

  test('Viewer can access Reports only', () async {
    final container = await loginAsRole('viewer', '8901');
    addTearDown(container.dispose);

    final perms = container.read(userPermissionsProvider);
    expect(perms, contains(Permissions.reports));
    expect(perms, isNot(contains('*')));

    expect(container.read(permissionProvider(Permissions.reports)), isTrue);
    // CANNOT access these
    expect(container.read(permissionProvider(Permissions.pos)), isFalse);
    expect(container.read(permissionProvider(Permissions.inventory)), isFalse);
    expect(container.read(permissionProvider(Permissions.settings)), isFalse);
    expect(container.read(permissionProvider(Permissions.users)), isFalse);
  });

  test('Logged-out user has no permissions', () {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final session = container.read(authSessionProvider);
    expect(session.isLoggedIn, isFalse);

    final perms = container.read(userPermissionsProvider);
    expect(perms, isEmpty);

    expect(container.read(permissionProvider(Permissions.pos)), isFalse);
    expect(container.read(permissionProvider(Permissions.invoices)), isFalse);
    expect(container.read(permissionProvider(Permissions.inventory)), isFalse);
  });

  test('Custom permissions override role defaults', () async {
    final salt = generateSalt();
    final pinHash = hashPin('1357', salt);

    await database.usersDao.insertUser(
      UsersCompanion(
        storeId: const Value(1),
        name: const Value('بائع مميز'),
        pinHash: Value(pinHash),
        pinSalt: Value(salt),
        role: const Value('pos_clerk'),
        permissions: const Value('["pos","invoices","inventory"]'),
      ),
    );

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final success =
        await container.read(authSessionProvider.notifier).loginWithPin('1357');
    expect(success, isTrue);

    // Custom permissions should override role defaults
    final perms = container.read(userPermissionsProvider);
    expect(perms, contains(Permissions.pos));
    expect(perms, contains(Permissions.invoices));
    expect(perms, contains(Permissions.inventory));
    expect(perms, isNot(contains('*')));

    // Has inventory access via custom override
    expect(container.read(permissionProvider(Permissions.inventory)), isTrue);
    // Still can't access reports
    expect(container.read(permissionProvider(Permissions.reports)), isFalse);
  });
}