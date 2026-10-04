/// feedbacks_dao.dart — DAO for feedbacks table
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'feedbacks_dao.g.dart';

@DriftAccessor(tables: [Feedbacks])
class FeedbacksDao extends DatabaseAccessor<AppDatabase>
    with _$FeedbacksDaoMixin {
  FeedbacksDao(super.db);

  /// All feedbacks, newest first.
  Future<List<Feedback>> getAllFeedbacks() =>
      (select(feedbacks)..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
          .get();

  /// Watch all feedbacks (reactive).
  Stream<List<Feedback>> watchAllFeedbacks() =>
      (select(feedbacks)..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
          .watch();

  /// Watch feedbacks filtered by type.
  Stream<List<Feedback>> watchByType(String type) =>
      (select(feedbacks)
            ..where((f) => f.type.equals(type))
            ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
          .watch();

  /// Feedbacks by a specific user.
  Future<List<Feedback>> getByUser(int userId) =>
      (select(feedbacks)
            ..where((f) => f.userId.equals(userId))
            ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();

  /// Insert a new feedback. Returns the new row id.
  Future<int> insertFeedback(FeedbacksCompanion companion) =>
      into(feedbacks).insert(companion);

  /// Update the status of a feedback.
  Future<void> updateStatus(int id, String status) =>
      (update(feedbacks)..where((f) => f.id.equals(id)))
          .write(FeedbacksCompanion(status: Value(status)));

  /// Delete a feedback.
  Future<int> deleteFeedback(int id) =>
      (delete(feedbacks)..where((f) => f.id.equals(id))).go();

  /// Count by status — for dashboard badges.
  Future<int> countByStatus(String status) async {
    final count = await (select(feedbacks)
          ..where((f) => f.status.equals(status)))
        .get();
    return count.length;
  }
}