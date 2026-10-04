/// locale_provider.dart — Riverpod notifier for app locale (ar/en)
///
/// US-013: Language toggle Arabic ↔ English
/// Instant switch without restart, RTL/LTR auto-switch.
/// Persists choice in Drift settings table.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/daos/settings_dao.dart';
import '../../features/inventory/providers/inventory_providers.dart';

// ─── Settings key ───

const _kLocaleKey = 'locale';

// ─── Locale Notifier ───

class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsDao _dao;

  LocaleNotifier(this._dao) : super(const Locale('ar', 'EG'));

  /// Load persisted locale on app start.
  Future<void> load() async {
    final code = await _dao.getValue(_kLocaleKey);
    if (code == 'en') {
      state = const Locale('en', 'US');
    }
  }

  /// Switch locale and persist.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _dao.upsertSetting(_kLocaleKey, locale.languageCode);
  }

  /// Toggle between ar and en.
  Future<void> toggle() async {
    if (state.languageCode == 'ar') {
      await setLocale(const Locale('en', 'US'));
    } else {
      await setLocale(const Locale('ar', 'EG'));
    }
  }

  /// Convenience getters.
  bool get isArabic => state.languageCode == 'ar';
  bool get isRTL => state.languageCode == 'ar';

  /// Current TextDirection.
  TextDirection get direction =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;
}

// ─── Providers ───

final _settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(appDatabaseProvider));
});

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final dao = ref.watch(_settingsDaoProvider);
  return LocaleNotifier(dao);
});

/// Derived provider: text direction for current locale.
final textDirectionProvider = Provider<TextDirection>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == 'ar'
      ? TextDirection.rtl
      : TextDirection.ltr;
});