/// users_dao.dart — DAO for users table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<List<User>> getAllUsers() => select(users).get();

  Future<List<User>> getUsersByStore(int storeId) =>
      (select(users)..where((u) => u.storeId.equals(storeId))).get();

  Future<User?> getUserById(int id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  /// Fetch all active users — PIN verification is done in application code
  /// by comparing SHA-256(salt + pin) against pinHash.
  Future<List<User>> getActiveUsers() =>
      (select(users)..where((u) => u.isActive.equals(true))).get();

  Future<int> insertUser(UsersCompanion companion) =>
      into(users).insert(companion);

  Future<bool> updateUser(User user) => update(users).replace(user);

  Future<int> deleteUser(int id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();

  Future<void> updateLastLogin(int userId) {
    return (update(users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(lastLogin: Value(DateTime.now())));
  }

  Future<void> setActive(int userId, bool active) {
    return (update(users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(isActive: Value(active)));
  }
}