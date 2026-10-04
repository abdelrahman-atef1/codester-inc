/// auth_providers.dart — Session, current user, and role state via Riverpod
///
/// Holds the logged-in user, exposes role helpers, and logs auth events
/// to the activity_log DAO.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart' as db;
import '../../../core/database/daos/users_dao.dart';
import '../../../core/database/daos/activity_log_dao.dart';
import '../../../core/utils/pin_hasher.dart';
import '../../inventory/providers/inventory_providers.dart' show appDatabaseProvider;

// ─── DAO Providers ───

final usersDaoProvider = Provider<UsersDao>((ref) {
  return UsersDao(ref.watch(appDatabaseProvider));
});

final authActivityLogDaoProvider = Provider<ActivityLogDao>((ref) {
  return ActivityLogDao(ref.watch(appDatabaseProvider));
});

// ─── Session State ───

/// Holds the currently logged-in user (null = logged out).
class AuthSession {
  final db.User? user;
  final bool isLoading;

  const AuthSession({this.user, this.isLoading = false});

  bool get isLoggedIn => user != null;
  bool get isOwner => user?.role == 'owner';
  bool get isClerk => user?.role == 'pos_clerk';
  bool get isInventoryManager => user?.role == 'inventory_manager';
  bool get isViewer => user?.role == 'viewer';

  /// Parsed permissions list from JSON column (null/empty = role-based defaults).
  List<String> get permissions {
    final raw = user?.permissions;
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  AuthSession copyWith({db.User? user, bool? isLoading}) {
    return AuthSession(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthSessionNotifier extends StateNotifier<AuthSession> {
  final UsersDao _usersDao;
  final ActivityLogDao _activityLogDao;

  AuthSessionNotifier(this._usersDao, this._activityLogDao)
      : super(const AuthSession());

  /// Attempts login with the given PIN against all active users.
  /// Returns true on success, false on failure.
  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(isLoading: true);
    try {
      final activeUsers = await _usersDao.getActiveUsers();
      for (final user in activeUsers) {
        if (verifyPin(pin, user.pinSalt, user.pinHash)) {
          await _usersDao.updateLastLogin(user.id);
          await _activityLogDao.insertLog(
            db.ActivityLogCompanion(
              userId: Value(user.id),
              action: const Value('login'),
              entityType: const Value('user'),
              entityId: Value(user.id),
              details: Value('تسجيل دخول: ${user.name}'),
            ),
          );
          state = AuthSession(user: user, isLoading: false);
          return true;
        }
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  void logout() {
    state = const AuthSession();
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession>((ref) {
  final usersDao = ref.watch(usersDaoProvider);
  final activityLogDao = ref.watch(authActivityLogDaoProvider);
  return AuthSessionNotifier(usersDao, activityLogDao);
});