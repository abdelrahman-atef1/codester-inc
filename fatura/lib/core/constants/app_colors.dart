/// app_colors.dart — Paper Ledger palette for Fatura
///
/// "الدفتر القديم" — inspired by old Egyptian merchant ledger books.
/// Cream paper, ink black, stamp red, forest green.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===== Paper Ledger Core =====
  static const Color background = Color(0xFFF5F0E1); // Cream paper
  static const Color surface = Color(0xFFEFE8D4); // Slightly darker cream (cards, nav)
  static const Color surfaceLight = Color(0xFFE8DFC9); // Hover / subtle fill
  static const Color card = Color(0xFFFBF7EB); // Lighter cream for card surfaces

  // ===== Ink =====
  static const Color ink = Color(0xFF2C2C2C); // Ink black — primary text
  static const Color inkLight = Color(0xFF4A4A4A); // Secondary text
  static const Color inkMuted = Color(0xFF8A8270); // Muted text / hints

  // ===== Stamp Red =====
  static const Color stampRed = Color(0xFFB83A3A); // Delete / error / warning
  static const Color stampRedLight = Color(0xFFD45D5D); // Lighter red for accents
  static const Color stampRedDark = Color(0xFF8F2A2A); // Darker red

  // ===== Forest Green =====
  static const Color forest = Color(0xFF2D6A4F); // Success / cash / completed
  static const Color forestLight = Color(0xFF40916C); // Lighter green
  static const Color forestDark = Color(0xFF1B4332); // Darker green

  // ===== Secondary Accents =====
  static const Color ochre = Color(0xFFB8860B); // Amber/ochre for warnings
  static const Color ochreLight = Color(0xFFD4A017);
  static const Color sepia = Color(0xFF7B5E3B); // Brown for misc accents
  static const Color indigo = Color(0xFF3D5A80); // Blue-ish for info

  // ===== Text Colors (aliased for clarity) =====
  static const Color textPrimary = ink;
  static const Color textSecondary = inkLight;
  static const Color textMuted = inkMuted;

  // ===== Status Colors (aliased) =====
  static const Color success = forest;
  static const Color warning = ochre;
  static const Color error = stampRed;
  static const Color info = indigo;

  // ===== Legacy aliases (keep for any code we missed) =====
  static const Color cyan = forest; // former cyan → forest green
  static const Color cyanDark = forestDark;
  static const Color cyanLight = forestLight;
  static const Color purple = sepia; // former purple → sepia brown
  static const Color purpleDark = sepia;
  static const Color purpleLight = Color(0xFF9B7B4F);

  // ===== POS Button — Stamp style =====
  static const Color posButtonBg = stampRed;
  static const Color posButtonGlow = Color(0x33B83A3A); // 20% opacity red glow

  // ===== Gradients =====
  static const LinearGradient forestGradient = LinearGradient(
    colors: [forest, forestDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [stampRed, stampRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Main brand gradient — ink to forest (subtle, like a stamp bleeding)
  static const LinearGradient brandGradient = LinearGradient(
    colors: [ink, forest],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ===== Material 3 Seed =====
  static const Color seed = forest;

  // ===== Ledger-specific =====
  /// Border color for "paper" cards — looks like drawn ink line
  static const Color ledgerBorder = Color(0xFFC9BFA8); // Warm grey-tan border
  static const Color ledgerLine = Color(0xFFD4CBB5); // Faint ruled line
}