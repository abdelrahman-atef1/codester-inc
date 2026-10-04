/// sync_metadata_dao.dart — DAO for sync_metadata table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'sync_metadata_dao.g.dart';

@DriftAccessor(tables: [SyncMetadata])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  Future<List<SyncMetadataData>> getAllMetadata() =>
      select(syncMetadata).get();

  Future<SyncMetadataData?> getMetadata(int id) =>
      (select(syncMetadata)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<SyncMetadataData?> getMetadataByDevice(String deviceId) =>
      (select(syncMetadata)..where((s) => s.deviceId.equals(deviceId)))
          .getSingleOrNull();

  Future<SyncMetadataData?> getOwnerMetadata() =>
      (select(syncMetadata)..where((s) => s.syncRole.equals('owner')))
          .getSingleOrNull();

  Future<SyncMetadataData?> getEmployeeMetadata() =>
      (select(syncMetadata)..where((s) => s.syncRole.equals('employee')))
          .getSingleOrNull();

  Stream<List<SyncMetadataData>> watchAllMetadata() =>
      select(syncMetadata).watch();

  Future<int> insertMetadata(SyncMetadataCompanion companion) =>
      into(syncMetadata).insert(companion);

  Future<bool> updateMetadata(SyncMetadataData data) =>
      update(syncMetadata).replace(data);

  Future<void> upsertMetadata({
    required String deviceId,
    required String syncRole,
    String? deviceName,
    DateTime? lastSyncAt,
    int pendingCount = 0,
  }) async {
    final existing = await getMetadataByDevice(deviceId);
    if (existing != null) {
      await (update(syncMetadata)..where((s) => s.deviceId.equals(deviceId)))
          .write(SyncMetadataCompanion(
        lastSyncAt: lastSyncAt != null ? Value(lastSyncAt) : const Value.absent(),
        pendingCount: Value(pendingCount),
        deviceName: deviceName != null ? Value(deviceName) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await into(syncMetadata).insert(SyncMetadataCompanion(
        deviceId: Value(deviceId),
        syncRole: Value(syncRole),
        deviceName: Value(deviceName),
        lastSyncAt: lastSyncAt != null ? Value(lastSyncAt) : const Value.absent(),
        pendingCount: Value(pendingCount),
      ));
    }
  }

  Future<void> updateLastSync(String deviceId, DateTime syncTime) async {
    await (update(syncMetadata)..where((s) => s.deviceId.equals(deviceId)))
        .write(SyncMetadataCompanion(
      lastSyncAt: Value(syncTime),
      pendingCount: const Value(0),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updatePendingCount(String deviceId, int count) async {
    await (update(syncMetadata)..where((s) => s.deviceId.equals(deviceId)))
        .write(SyncMetadataCompanion(
      pendingCount: Value(count),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<int> deleteMetadata(int id) =>
      (delete(syncMetadata)..where((s) => s.id.equals(id))).go();
}