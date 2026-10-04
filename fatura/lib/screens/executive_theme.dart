/// bold_executive_theme.dart — Shared constants for the Stitch
/// "Bold Executive" designs (POS dashboard + invoice receipt).
///
/// Colors come straight from the Stitch HTML Tailwind config:
///   brand.red    #E63946
///   brand.teal   #2A9D8F
///   brand.slate  #1E293B  (dark surface)
///   brand.bg     #F1F5F9
///   brand.darkText #0F172A
///   brand.muted  #64748B
///   brand.border #E2E8F0
///   brand.amber  #F59E0B
///
/// Typography: Cairo (bold weights for headers) via google_fonts.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExecutiveColors {
  ExecutiveColors._();

  static const Color red = Color(0xFFE63946);
  static const Color redDark = Color(0xFFB91C2C);
  static const Color teal = Color(0xFF2A9D8F);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceAlt = Color(0xFF0F172A); // slate-900
  static const Color background = Color(0xFFF1F5F9);
  static const Color darkText = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color amber = Color(0xFFF59E0B);

  // Slate scale used by the dark header / cart panel
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Emerald accents (shift badge, "paid" status, drawer state)
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald950 = Color(0xFF022C22);

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal800 = Color(0xFF115E59);
  static const Color teal900 = Color(0xFF134E4A);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red400 = Color(0xFFF87171);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red950 = Color(0xFF450A0A);
}

/// Cairo text helpers (bold weights for headers, per the design).
class ExecutiveText {
  ExecutiveText._();

  static TextStyle get headline => GoogleFonts.cairo(
        fontWeight: FontWeight.w800,
        color: ExecutiveColors.darkText,
        height: 1.25,
      );

  static TextStyle get title => GoogleFonts.cairo(
        fontWeight: FontWeight.w700,
        color: ExecutiveColors.darkText,
        height: 1.3,
      );

  static TextStyle get body => GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        color: ExecutiveColors.darkText,
      );

  static TextStyle get label => GoogleFonts.cairo(
        fontWeight: FontWeight.w500,
        color: ExecutiveColors.muted,
      );

  /// Numerals with tabular spacing for money columns.
  static TextStyle get tabular => GoogleFonts.cairo(
        fontWeight: FontWeight.w700,
        color: ExecutiveColors.darkText,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
