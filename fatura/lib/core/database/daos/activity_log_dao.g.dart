// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_dao.dart';

// ignore_for_file: type=lint
mixin _$ActivityLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $StoresTable get stores => attachedDatabase.stores;
  $UsersTable get users => attachedDatabase.users;
  $ActivityLogTable get activityLog => attachedDatabase.activityLog;
  ActivityLogDaoManager get managers => ActivityLogDaoManager(this);
}

class ActivityLogDaoManager {
  final _$ActivityLogDaoMixin _db;
  ActivityLogDaoManager(this._db);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db.attachedDatabase, _db.stores);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$ActivityLogTableTableManager get activityLog =>
      $$ActivityLogTableTableManager(_db.attachedDatabase, _db.activityLog);
}
