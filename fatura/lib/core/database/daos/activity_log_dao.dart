/// activity_log_dao.dart — DAO for activity_log table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'activity_log_dao.g.dart';

@DriftAccessor(tables: [ActivityLog])
class ActivityLogDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityLogDaoMixin {
  ActivityLogDao(super.db);

  Future<List<ActivityLogData>> getAllLogs() =>
      (select(activityLog)..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .get();

  Stream<List<ActivityLogData>> watchAllLogs() =>
      (select(activityLog)..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .watch();

  Future<List<ActivityLogData>> getLogsByUser(int userId) {
    return (select(activityLog)
          ..where((a) => a.userId.equals(userId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  Future<List<ActivityLogData>> getLogsByAction(String action) {
    return (select(activityLog)
          ..where((a) => a.action.equals(action))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  Future<List<ActivityLogData>> getLogsByEntity(
      String entityType, int entityId) {
    return (select(activityLog)
          ..where((a) =>
              a.entityType.equals(entityType) & a.entityId.equals(entityId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  Future<int> insertLog(ActivityLogCompanion companion) =>
      into(activityLog).insert(companion);

  Future<int> deleteLog(int id) =>
      (delete(activityLog)..where((a) => a.id.equals(id))).go();

  Future<int> deleteOldLogs(DateTime before) {
    return (delete(activityLog)
          ..where((a) => a.createdAt.isSmallerThanValue(before)))
        .go();
  }
}