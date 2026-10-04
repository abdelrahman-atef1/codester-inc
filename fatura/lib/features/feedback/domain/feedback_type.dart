/// feedback_type.dart — Enums for the Feedback module
///
/// Feedback types (bug / feature_request / improvement)
/// and priority levels (low / medium / high).
library;

/// Type of feedback a user can submit.
enum FeedbackType {
  bug,
  featureRequest,
  improvement;

  /// String stored in the database.
  String get dbValue {
    switch (this) {
      case FeedbackType.bug:
        return 'bug';
      case FeedbackType.featureRequest:
        return 'feature_request';
      case FeedbackType.improvement:
        return 'improvement';
    }
  }

  /// Arabic label shown in the UI.
  String get labelAr {
    switch (this) {
      case FeedbackType.bug:
        return 'مشكلة';
      case FeedbackType.featureRequest:
        return 'طلب ميزة';
      case FeedbackType.improvement:
        return 'اقتراح تحسين';
    }
  }

  /// Icon representing the type.
  String get iconName {
    switch (this) {
      case FeedbackType.bug:
        return 'bug_report';
      case FeedbackType.featureRequest:
        return 'lightbulb';
      case FeedbackType.improvement:
        return 'tune';
    }
  }

  /// Parse from database string.
  static FeedbackType fromDb(String value) {
    switch (value) {
      case 'bug':
        return FeedbackType.bug;
      case 'feature_request':
        return FeedbackType.featureRequest;
      case 'improvement':
      default:
        return FeedbackType.improvement;
    }
  }
}

/// Priority level — optional.
enum FeedbackPriority {
  low,
  medium,
  high;

  String get dbValue => name;

  String get labelAr {
    switch (this) {
      case FeedbackPriority.low:
        return 'منخفضة';
      case FeedbackPriority.medium:
        return 'متوسطة';
      case FeedbackPriority.high:
        return 'عالية';
    }
  }

  static FeedbackPriority? fromDb(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'low':
        return FeedbackPriority.low;
      case 'medium':
        return FeedbackPriority.medium;
      case 'high':
        return FeedbackPriority.high;
      default:
        return null;
    }
  }
}

/// Status of a feedback item — managed by the owner.
enum FeedbackStatus {
  new_,
  read,
  resolved;

  String get dbValue {
    switch (this) {
      case FeedbackStatus.new_:
        return 'new';
      case FeedbackStatus.read:
        return 'read';
      case FeedbackStatus.resolved:
        return 'resolved';
    }
  }

  String get labelAr {
    switch (this) {
      case FeedbackStatus.new_:
        return 'جديد';
      case FeedbackStatus.read:
        return 'مقروء';
      case FeedbackStatus.resolved:
        return 'محلول';
    }
  }

  static FeedbackStatus fromDb(String value) {
    switch (value) {
      case 'new':
        return FeedbackStatus.new_;
      case 'read':
        return FeedbackStatus.read;
      case 'resolved':
      default:
        return FeedbackStatus.resolved;
    }
  }
}