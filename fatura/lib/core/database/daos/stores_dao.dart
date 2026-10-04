/// stores_dao.dart — DAO for stores table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'stores_dao.g.dart';

@DriftAccessor(tables: [Stores])
class StoresDao extends DatabaseAccessor<AppDatabase> with _$StoresDaoMixin {
  StoresDao(super.db);

  Future<List<Store>> getAllStores() => select(stores).get();

  Future<Store?> getStoreById(int id) =>
      (select(stores)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<Store?> getFirstStore() => select(stores).getSingleOrNull();

  Stream<Store?> watchFirstStore() => select(stores).watchSingleOrNull();

  Future<int> insertStore(StoresCompanion companion) =>
      into(stores).insert(companion);

  Future<bool> updateStore(Store store) => update(stores).replace(store);

  Future<int> deleteStore(int id) =>
      (delete(stores)..where((s) => s.id.equals(id))).go();

  Future<void> updateStoreFields(int id, StoresCompanion companion) {
    return (update(stores)..where((s) => s.id.equals(id))).write(companion);
  }
}