/// main.dart — Entry point for Fatura app
///
/// Sets up ProviderScope, theme, router, RTL/LTR direction (reactive),
/// locale (ar/en instant switch), and offline banner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/widgets/offline_banner.dart';

void main() {
  runApp(const ProviderScope(child: FaturaApp()));
}

class FaturaApp extends ConsumerStatefulWidget {
  const FaturaApp({super.key});

  @override
  ConsumerState<FaturaApp> createState() => _FaturaAppState();
}

class _FaturaAppState extends ConsumerState<FaturaApp> {
  // Default to online; in a real app this would check connectivity
  final bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Load persisted locale on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final textDirection = ref.watch(textDirectionProvider);

    return MaterialApp.router(
      title: 'فاتورة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(routerProvider),
      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      locale: locale,
      // RTL/LTR auto-switch based on locale
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: OfflineBanner(
            isOffline: _isOffline,
            child: child!,
          ),
        );
      },
    );
  }
}