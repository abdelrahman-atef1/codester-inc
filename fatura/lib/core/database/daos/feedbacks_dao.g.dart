// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedbacks_dao.dart';

// ignore_for_file: type=lint
mixin _$FeedbacksDaoMixin on DatabaseAccessor<AppDatabase> {
  $StoresTable get stores => attachedDatabase.stores;
  $UsersTable get users => attachedDatabase.users;
  $FeedbacksTable get feedbacks => attachedDatabase.feedbacks;
  FeedbacksDaoManager get managers => FeedbacksDaoManager(this);
}

class FeedbacksDaoManager {
  final _$FeedbacksDaoMixin _db;
  FeedbacksDaoManager(this._db);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db.attachedDatabase, _db.stores);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$FeedbacksTableTableManager get feedbacks =>
      $$FeedbacksTableTableManager(_db.attachedDatabase, _db.feedbacks);
}
