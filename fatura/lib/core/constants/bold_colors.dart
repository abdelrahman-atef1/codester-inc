/// bold_colors.dart — "Bold Executive" palette for Fatura (Stitch-redesign)
///
/// Red + teal modern look matching stitch-designs/03-inventory.html &
/// 04-reports.html.
///   * primary   #E63946  (crimson red)
///   * accent    #2A9D8F  (teal)
///   * dark      #1E293B  (slate-800 header)
///   * bg        #F1F5F9  (slate-100 screen background)
///   * warning   #F59E0B  (amber)
library;

import 'package:flutter/material.dart';

class BoldColors {
  BoldColors._();

  // ===== Bold Executive Brand =====
  static const Color primary = Color(0xFFE63946); // crimson red
  static const Color accent = Color(0xFF2A9D8F); // teal
  static const Color dark = Color(0xFF1E293B); // slate-800 (app bar / hero)
  static const Color bg = Color(0xFFF1F5F9); // slate-100 (screen bg)
  static const Color warning = Color(0xFFF59E0B); // amber

  // ===== Neutrals =====
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderStrong = Color(0xFFCBD5E1); // slate-300
  static const Color text = Color(0xFF0F172A); // slate-900
  static const Color textLight = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF64748B); // slate-500
  static const Color textFaint = Color(0xFF94A3B8); // slate-400
  static const Color chipGrey = Color(0xFFF1F5F9); // slate-100

  // ===== Teal tinted surfaces (in-stock pill / top-5 badge) =====
  static const Color tealBg = Color(0xFFF0FDFA); // teal-50
  static const Color tealBorder = Color(0xFF99F6E4); // teal-200
  static const Color tealText = Color(0xFF0F766E); // teal-700

  // ===== Amber tinted surfaces (low-stock) =====
  static const Color amberBg = Color(0xFFFFFBEB); // amber-50
  static const Color amberBorder = Color(0xFFFCD34D); // amber-300
  static const Color amberText = Color(0xFF92400E); // amber-800
  static const Color amberIcon = Color(0xFF92400E); // amber-800
  static const Color amverDotWarn = Color(0xFFF59E0B); // amber-500 pulse dot

  // ===== Red tinted surfaces (out-of-stock) =====
  static const Color redBg = Color(0xFFFEF2F2); // red-50
  static const Color redBorder = Color(0xFFFECACA); // red-200
  static const Color redText = Color(0xFFDC2626); // red-600

  // ===== Hero gradient (dark) =====
  static const Color heroCardDark = Color(0xFF0F172A); // slate-900
  static const Color heroCardLine = Color(0xFF1E293B); // slate-800
}
