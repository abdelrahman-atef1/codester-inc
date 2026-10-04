// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stores_dao.dart';

// ignore_for_file: type=lint
mixin _$StoresDaoMixin on DatabaseAccessor<AppDatabase> {
  $StoresTable get stores => attachedDatabase.stores;
  StoresDaoManager get managers => StoresDaoManager(this);
}

class StoresDaoManager {
  final _$StoresDaoMixin _db;
  StoresDaoManager(this._db);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db.attachedDatabase, _db.stores);
}
