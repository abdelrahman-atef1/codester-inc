/// feedback_providers.dart — Riverpod providers for the Feedback module
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/daos/feedbacks_dao.dart';
import '../../auth/providers/auth_providers.dart';
import '../../inventory/providers/inventory_providers.dart' show appDatabaseProvider;
import '../domain/feedback_type.dart';

// ─── DAO Provider ───

final feedbacksDaoProvider = Provider<FeedbacksDao>((ref) {
  return FeedbacksDao(ref.watch(appDatabaseProvider));
});

// ─── Filter State ───

/// Filter for the feedback list: null = all, otherwise type string.
final feedbackFilterProvider = StateProvider<String?>((ref) => null);

// ─── Reactive Lists ───

/// All feedbacks (reactive).
final allFeedbacksProvider = StreamProvider<List<Feedback>>((ref) {
  final dao = ref.watch(feedbacksDaoProvider);
  return dao.watchAllFeedbacks();
});

/// Filtered feedbacks based on [feedbackFilterProvider].
final filteredFeedbacksProvider = StreamProvider<List<Feedback>>((ref) {
  final dao = ref.watch(feedbacksDaoProvider);
  final filter = ref.watch(feedbackFilterProvider);

  if (filter == null) {
    return dao.watchAllFeedbacks();
  } else {
    return dao.watchByType(filter);
  }
});

// ─── Actions ───

/// Notifier that handles submitting feedback.
class FeedbackSubmitNotifier extends StateNotifier<bool> {
  final FeedbacksDao _dao;
  final AuthSession _session;

  FeedbackSubmitNotifier(this._dao, this._session) : super(false);

  /// Submit a new feedback entry. Returns true on success.
  Future<bool> submit({
    required FeedbackType type,
    required String title,
    required String description,
    FeedbackPriority? priority,
  }) async {
    state = true;
    try {
      await _dao.insertFeedback(
        FeedbacksCompanion.insert(
          type: type.dbValue,
          title: title.trim(),
          description: description.trim(),
          priority: priority != null ? Value(priority.dbValue) : const Value.absent(),
          status: const Value('new'),
          userId: _session.user != null ? Value(_session.user!.id) : const Value.absent(),
          createdAt: Value(DateTime.now()),
        ),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      state = false;
    }
  }
}

final feedbackSubmitProvider =
    StateNotifierProvider<FeedbackSubmitNotifier, bool>((ref) {
  final dao = ref.watch(feedbacksDaoProvider);
  final session = ref.watch(authSessionProvider);
  return FeedbackSubmitNotifier(dao, session);
});

/// Notifier that handles status changes (owner only).
class FeedbackStatusNotifier extends StateNotifier<bool> {
  final FeedbacksDao _dao;

  FeedbackStatusNotifier(this._dao) : super(false);

  Future<void> updateStatus(int feedbackId, FeedbackStatus status) async {
    state = true;
    try {
      await _dao.updateStatus(feedbackId, status.dbValue);
    } finally {
      state = false;
    }
  }
}

final feedbackStatusProvider =
    StateNotifierProvider<FeedbackStatusNotifier, bool>((ref) {
  final dao = ref.watch(feedbacksDaoProvider);
  return FeedbackStatusNotifier(dao);
});