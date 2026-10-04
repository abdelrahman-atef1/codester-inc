/// payment_method.dart — Payment method enum for POS checkout
///
/// T-013: نقداً / بطاقة / محفظة إلكترونية
library;

import 'dart:ui' show Color;

import '../../../../core/constants/app_colors.dart';

enum PaymentMethod {
  cash,
  card,
  wallet;

  /// Arabic label
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.card:
        return 'بطاقة';
      case PaymentMethod.wallet:
        return 'محفظة إلكترونية';
    }
  }

  /// Icon for selector
  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.wallet:
        return '📱';
    }
  }

  /// Accent color per method
  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return AppColors.forest;
      case PaymentMethod.card:
        return AppColors.indigo;
      case PaymentMethod.wallet:
        return AppColors.sepia;
    }
  }
}