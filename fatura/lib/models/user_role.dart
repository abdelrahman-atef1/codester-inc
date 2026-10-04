/// user_role.dart — Role-based permission model for Fatura
///
/// Defines the four staff roles and their capability flags.
/// Each role maps cleanly onto the string permission keys used by
/// `permission_providers.dart` and the route guards in `app_router.dart`.
///
/// Usage:
///   final role = UserRole.fromString(dbUser.role);
///   if (role.canSell) { /* show POS */ }
library;

/// Staff roles supported by Fatura.
enum UserRole {
  /// Full access to every screen and action.
  owner,

  /// Front-of-house cashier — POS and invoices only.
  posClerk,

  /// Back-of-house — inventory management only.
  inventoryManager,

  /// Read-only — can view reports but cannot change data.
  viewer;

  /// Parse a role string from the database.
  ///
  /// Accepts both snake_case ('pos_clerk') and the canonical
  /// lower-case-with-underscore form stored in `users.role`.
  /// Falls back to [UserRole.viewer] for unknown values (most restrictive).
  static UserRole fromString(String value) {
    switch (value) {
      case 'owner':
        return UserRole.owner;
      case 'pos_clerk':
      case 'posClerk':
        return UserRole.posClerk;
      case 'inventory_manager':
      case 'inventoryManager':
        return UserRole.inventoryManager;
      case 'viewer':
        return UserRole.viewer;
      default:
        return UserRole.viewer;
    }
  }

  /// Canonical string persisted in `users.role`.
  String get dbValue {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.posClerk:
        return 'pos_clerk';
      case UserRole.inventoryManager:
        return 'inventory_manager';
      case UserRole.viewer:
        return 'viewer';
    }
  }

  // ─── Capability flags ───

  /// Owner + pos_clerk may ring up sales in the POS.
  bool get canSell =>
      this == UserRole.owner || this == UserRole.posClerk;

  /// Owner + inventory_manager may add/edit/delete products.
  bool get canManageInventory =>
      this == UserRole.owner || this == UserRole.inventoryManager;

  /// Everyone except inventory-only staff may view reports;
  /// the viewer role exists specifically for this.
  bool get canViewReports =>
      this == UserRole.owner || this == UserRole.viewer;

  /// Only the owner may add/edit/deactivate staff or view the activity log.
  bool get canManageUsers => this == UserRole.owner;

  // ─── Permission keys mapping ───

  /// The string permission keys this role grants by default.
  ///
  /// Matches `_roleDefaults` in `permission_providers.dart`.
  List<String> get defaultPermissions {
    switch (this) {
      case UserRole.owner:
        return const ['*'];
      case UserRole.posClerk:
        return const ['pos', 'invoices'];
      case UserRole.inventoryManager:
        return const ['inventory'];
      case UserRole.viewer:
        return const ['reports'];
    }
  }

  /// Arabic display label for the role.
  String get labelAr {
    switch (this) {
      case UserRole.owner:
        return 'المالك';
      case UserRole.posClerk:
        return 'كاشير';
      case UserRole.inventoryManager:
        return 'أمين مخزن';
      case UserRole.viewer:
        return 'مشاهد';
    }
  }
}
