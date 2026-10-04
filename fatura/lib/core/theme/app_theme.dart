/// app_theme.dart — Material 3 LIGHT theme for Fatura (Paper Ledger)
///
/// "الدفتر القديم" — Old paper ledger aesthetic.
/// Cream paper bg, ink black text, stamp red accents, forest green success.
/// Cards with borders (not shadows), underline inputs, flat bordered buttons.
/// Fonts: Cairo (Arabic primary), Tajawal (fallback)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  AppTheme._();

  /// Main theme — Paper Ledger LIGHT
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
      primary: AppColors.forest,
      secondary: AppColors.stampRed,
      surface: AppColors.surface,
      error: AppColors.stampRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontLG,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        hintStyle: const TextStyle(color: AppColors.inkMuted),
        // Underline style — like writing in a ledger
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.forest, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.stampRed, width: 1.5),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.stampRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSM,
          vertical: AppSizes.paddingMD,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.background,
          minimumSize: const Size(AppSizes.buttonWidth, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            side: const BorderSide(color: AppColors.forestDark, width: 1),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: AppSizes.fontLG,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          minimumSize: const Size(AppSizes.buttonWidth, AppSizes.buttonHeight),
          side: const BorderSide(color: AppColors.forest, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.forest,
        unselectedItemColor: AppColors.inkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.background,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ledgerLine,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.ink,
        size: AppSizes.iconMD,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontDisplay,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontXXL,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontXL,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontLG,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontLG,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontSM,
          fontWeight: FontWeight.w500,
          color: AppColors.inkLight,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontSM,
          fontWeight: FontWeight.w400,
          color: AppColors.inkLight,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontXS,
          fontWeight: FontWeight.w400,
          color: AppColors.inkMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontSM,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontXS,
          fontWeight: FontWeight.w500,
          color: AppColors.inkLight,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.background,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLG),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.forest.withValues(alpha: 0.15),
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.ink,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          side: const BorderSide(color: AppColors.ledgerBorder, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.forest,
        textColor: AppColors.ink,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.forest,
      ),
    );
  }

  /// Dark theme alias — kept for compatibility, returns light theme
  static ThemeData get darkTheme => lightTheme;
}