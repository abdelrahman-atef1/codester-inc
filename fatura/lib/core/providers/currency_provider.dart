/// currency_provider.dart — Riverpod providers for currency selection & formatting
///
/// US-014: Currency selector (EGP, SAR, AED, KWD, USD)
/// Persists choice in Drift settings table, formats all prices via intl.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/daos/settings_dao.dart';
import '../utils/formatters.dart';
import '../../features/inventory/providers/inventory_providers.dart';

// ─── Currency Model ───

/// Supported currencies in Fatura.
class CurrencyInfo {
  final String code;   // EGP, SAR, ...
  final String symbol; // ج.م, ر.س, ...
  final String nameAr; // جنيه مصري, ريال سعودي, ...
  final String locale; // ar_EG, ar_SA, ...
  final int decimalDigits;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.nameAr,
    required this.locale,
    this.decimalDigits = 2,
  });

  static const List<CurrencyInfo> all = [
    CurrencyInfo(code: 'EGP', symbol: 'ج.م', nameAr: 'جنيه مصري', locale: 'ar_EG'),
    CurrencyInfo(code: 'SAR', symbol: 'ر.س', nameAr: 'ريال سعودي', locale: 'ar_SA'),
    CurrencyInfo(code: 'AED', symbol: 'د.إ', nameAr: 'درهم إماراتي', locale: 'ar_AE'),
    CurrencyInfo(code: 'KWD', symbol: 'د.ك', nameAr: 'دينار كويتي', locale: 'ar_KW', decimalDigits: 3),
    CurrencyInfo(code: 'USD', symbol: '\$', nameAr: 'دولار أمريكي', locale: 'en_US'),
  ];

  static CurrencyInfo byCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => all.first);
}

// ─── Settings keys ───

const _kCurrencyKey = 'currency_code';

// ─── DAO provider (re-export to avoid circular imports) ───

final _settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(appDatabaseProvider));
});

// ─── Currency Notifier ───

class CurrencyNotifier extends StateNotifier<CurrencyInfo> {
  final SettingsDao _dao;

  CurrencyNotifier(this._dao)
      : super(CurrencyInfo.byCode('EGP'));

  /// Load persisted currency on app start.
  Future<void> load() async {
    final code = await _dao.getValue(_kCurrencyKey);
    if (code != null) {
      state = CurrencyInfo.byCode(code);
    }
  }

  /// Switch currency and persist.
  Future<void> setCurrency(String code) async {
    state = CurrencyInfo.byCode(code);
    await _dao.upsertSetting(_kCurrencyKey, code);
  }
}

// ─── Providers ───

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyInfo>((ref) {
  final dao = ref.watch(_settingsDaoProvider);
  return CurrencyNotifier(dao);
});

/// Currency formatter that reacts to current currency selection.
final currencyFormatterProvider = Provider<NumberFormat>((ref) {
  final currency = ref.watch(currencyProvider);
  return NumberFormat.currency(
    symbol: currency.symbol,
    decimalDigits: currency.decimalDigits,
    locale: currency.locale,
  );
});

/// Extension method for quick formatting.
extension CurrencyFormatExtension on Ref {
  String formatMoney(double amount) {
    final formatter = watch(currencyFormatterProvider);
    return formatter.format(amount);
  }
}

/// Helper function for one-off formatting (non-reactive).
String formatCurrency(double amount, CurrencyInfo currency) {
  return Formatters.formatCurrency(
    amount,
    symbol: currency.symbol,
    decimalDigits: currency.decimalDigits,
    locale: currency.locale,
  );
}