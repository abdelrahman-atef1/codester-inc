/// app_sizes.dart — Design system sizing constants for Fatura
///
/// Follows Material 3 spacing scale with custom additions.
library;

class AppSizes {
  AppSizes._();

  // ===== Spacing =====
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ===== Padding =====
  static const double paddingXS = 4;
  static const double paddingSM = 8;
  static const double paddingMD = 16;
  static const double paddingLG = 24;
  static const double paddingXL = 32;

  // ===== Border Radius =====
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 24;
  static const double radiusCircle = 100;

  // ===== Component Sizes =====
  static const double buttonHeight = 52;
  static const double buttonWidth = double.infinity;
  static const double buttonRadius = 12;

  static const double inputHeight = 56;
  static const double inputRadius = 12;

  static const double cardRadius = 16;
  static const double cardElevation = 0; // flat design in dark theme

  static const double posButtonSize = 64; // circular POS button
  static const double posButtonIconSize = 32;

  // ===== Bottom Nav =====
  static const double bottomNavHeight = 72;
  static const double bottomNavItemSize = 24;

  // ===== Sidebar (Tablet/Web) =====
  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 72;

  // ===== Breakpoints =====
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  // ===== Font Sizes =====
  static const double fontXS = 11;
  static const double fontSM = 13;
  static const double fontMD = 15;
  static const double fontLG = 18;
  static const double fontXL = 22;
  static const double fontXXL = 28;
  static const double fontDisplay = 36;

  // ===== Icon Sizes =====
  static const double iconSM = 16;
  static const double iconMD = 24;
  static const double iconLG = 32;
  static const double iconXL = 48;

  // ===== Animation Durations (from animation-spec.md) =====
  static const Duration durationMicro = Duration(milliseconds: 150);
  static const Duration durationShort = Duration(milliseconds: 250);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationLong = Duration(milliseconds: 500);
  static const Duration durationExtra = Duration(milliseconds: 800);

  // ===== Page Transition Durations =====
  static const Duration transitionSlide = Duration(milliseconds: 300);
  static const Duration transitionFade = Duration(milliseconds: 400);
  static const Duration transitionScale = Duration(milliseconds: 400);
  static const Duration transitionTab = Duration(milliseconds: 250);
}