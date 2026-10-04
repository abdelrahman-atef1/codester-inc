/// permission_providers.dart — Riverpod permission guards (US-020, US-021)
///
/// Role-based access control for every screen.
///   owner            → everything
///   pos_clerk        → POS + Invoices only
///   inventory_manager→ Inventory only
///   viewer           → Reports only
///
/// Usage in screens:
///   final canAccess = ref.watch(permissionProvider('inventory'));
///   if (!canAccess) → redirect to login / forbidden.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';

// ─── Permission Keys ───

abstract final class Permissions {
  static const String pos = 'pos';
  static const String invoices = 'invoices';
  static const String inventory = 'inventory';
  static const String reports = 'reports';
  static const String settings = 'settings';
  static const String users = 'users';
  static const String activityLog = 'activity_log';
  static const String everything = '*';
}

/// Default permission sets per role.
const Map<String, List<String>> _roleDefaults = {
  'owner': ['*'],
  'pos_clerk': ['pos', 'invoices'],
  'inventory_manager': ['inventory'],
  'viewer': ['reports'],
};

/// All known permission keys (for the UI checkboxes).
const List<String> allPermissionKeys = [
  Permissions.pos,
  Permissions.invoices,
  Permissions.inventory,
  Permissions.reports,
  Permissions.settings,
  Permissions.users,
  Permissions.activityLog,
];

/// Arabic labels for each permission key.
const Map<String, String> permissionLabelsAr = {
  Permissions.pos: 'نقطة البيع',
  Permissions.invoices: 'الفواتير',
  Permissions.inventory: 'المخزون',
  Permissions.reports: 'التقارير',
  Permissions.settings: 'الإعدادات',
  Permissions.users: 'الموظفين',
  Permissions.activityLog: 'سجل النشاط',
};

// ─── Providers ───

/// The effective permission list for the current user:
///  - If the user has a custom permissions JSON column → use it.
///  - Otherwise fall back to the role defaults.
final userPermissionsProvider = Provider<List<String>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (!session.isLoggedIn) return [];

  // Custom permissions from user record take precedence.
  final custom = session.permissions;
  if (custom.isNotEmpty) return custom;

  // Fall back to role defaults.
  return _roleDefaults[session.user!.role] ?? [];
});

/// Boolean guard: does the current user have [key]?
/// Use '*' to check for any permission (i.e. is logged in).
final permissionProvider = Provider.family<bool, String>((ref, key) {
  final perms = ref.watch(userPermissionsProvider);
  if (perms.contains('*')) return true; // owner wildcard
  return perms.contains(key);
});

/// True if the current user can access [key] (alias for readability).
bool canAccess(WidgetRef ref, String key) =>
    ref.watch(permissionProvider(key));

/// Route guard: returns the route to redirect to if the current user
/// is **not** allowed to access [key]; returns null if allowed.
String? guardRoute(WidgetRef ref, String key) {
  final session = ref.watch(authSessionProvider);
  if (!session.isLoggedIn) return '/login';
  if (!ref.watch(permissionProvider(key))) {
    // Send to invoices (safe default) or login if no permission.
    return '/invoices';
  }
  return null;
}