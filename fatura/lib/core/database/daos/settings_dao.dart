/// settings_dao.dart — DAO for settings table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<List<Setting>> getAllSettings() => select(settings).get();

  Future<Setting?> getSetting(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();

  Stream<Setting?> watchSetting(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).watchSingleOrNull();

  Future<String?> getValue(String key) async {
    final setting = await getSetting(key);
    return setting?.value;
  }

  Future<int> insertSetting(SettingsCompanion companion) =>
      into(settings).insert(companion);

  Future<void> upsertSetting(String key, String value) async {
    final existing = await getSetting(key);
    if (existing != null) {
      await (update(settings)..where((s) => s.key.equals(key)))
          .write(SettingsCompanion(value: Value(value)));
    } else {
      await into(settings)
          .insert(SettingsCompanion(key: Value(key), value: Value(value)));
    }
  }

  Future<int> deleteSetting(String key) =>
      (delete(settings)..where((s) => s.key.equals(key))).go();
}