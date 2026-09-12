import 'package:flutter/material.dart';
import '../enums/age_group.dart';
import '../theme/persona_theme.dart';

/// Design Tokens that adapt based on the current PersonaTheme.
///
/// All UI components reference these tokens. When the user's age group changes,
/// the tokens update automatically and the entire UI adapts.
class DesignTokens {
  DesignTokens._();

  // ─────────────────────────────────────────────
  // CURRENT PERSONA (set at runtime)
  // ─────────────────────────────────────────────

  static PersonaTheme _current = PersonaTheme.adultTheme;

  /// Initialize tokens with a specific persona.
  static void init(PersonaTheme theme) {
    _current = theme;
  }

  /// Get current persona.
  static PersonaTheme get current => _current;

  /// Get current age group.
  static AgeGroup get ageGroup => _current.ageGroup;

  // ─────────────────────────────────────────────
  // COLOR ROLES (from persona)
  // ─────────────────────────────────────────────

  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get surfaceRaised => _current.surfaceRaised;
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get textMuted => _current.textMuted;
  static Color get border => _current.border;
  static Color get accent => _current.primary;
  static Color get primary => _current.primary;
  static Color get accentLight => _current.primaryLight;
  static Color get accentSecondary => _current.secondary;
  static Color get accentSecondaryLight => _current.secondaryLight;
  static Color get accentTertiary => _current.accent;
  static Color get success => _current.success;
  static Color get warning => _current.warning;
  static Color get danger => _current.danger;
  static Color get error => _current.danger;

  // ─────────────────────────────────────────────
  // SPACING (4px base grid — universal)
  // ─────────────────────────────────────────────

  static const double spacing0 = 0;
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing14 = 14;
  static const double spacing16 = 16;
  static const double spacing18 = 18;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;

  static const double spacingTight = 8;
  static const double spacingMedium = 16;
  static const double spacingWide = 24;
  static const double spacingVast = 48;

  // ─────────────────────────────────────────────
  // BORDER RADIUS (from persona)
  // ─────────────────────────────────────────────

  static double get radius0 => 0;
  static double get radius4 => 4;
  static double get radius6 => 6;
  static double get radius8 => 8;
  static double get radius10 => 10;
  static double get radius12 => 12;
  static double get radius14 => 14;
  static double get radius16 => 16;
  static double get radius20 => _current.borderRadius;
  static double get radius24 => 24;
  static double get radius40 => 40;
  static double get radiusRound => 999;

  // ─────────────────────────────────────────────
  // TYPOGRAPHY
  // ─────────────────────────────────────────────

  static String get fontFamilyPrimary => _current.fontFamily;
  static String get fontFamilyDisplay => _current.fontFamily;

  static const double fontSizeH1 = 28;
  static const double fontSizeH2 = 24;
  static const double fontSizeH3 = 20;
  static const double fontSizeBody = 16;
  static const double fontSizeBodySmall = 14;
  static const double fontSizeCaption = 12;

  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightRegular = FontWeight.w400;

  static const double lineHeightHeading = 1.2;
  static const double lineHeightBody = 1.5;

  // ─────────────────────────────────────────────
  // SHADOW / ELEVATION (adapt to light/dark persona)
  // ─────────────────────────────────────────────

  static List<BoxShadow> get shadowFlat => [];

  static List<BoxShadow> get shadowRaised {
    if (_current.isDark) {
      return const [
        BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 4),
        BoxShadow(color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 0),
      ];
    }
    return const [
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
      BoxShadow(color: Color(0x0D000000), offset: Offset(0, 2), blurRadius: 6),
    ];
  }

  static List<BoxShadow> get shadowFloating {
    if (_current.isDark) {
      return const [
        BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 10),
        BoxShadow(color: Color(0x0D000000), offset: Offset(0, 2), blurRadius: 15),
      ];
    }
    return const [
      BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 12),
      BoxShadow(color: Color(0x0D000000), offset: Offset(0, 8), blurRadius: 24),
    ];
  }

  static List<BoxShadow> get shadowOverlay => [
    BoxShadow(
      color: _current.isDark
          ? const Color(0x1A000000)
          : const Color(0x33000000),
      offset: const Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  // ─────────────────────────────────────────────
  // MOTION
  // ─────────────────────────────────────────────

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionNormal = Duration(milliseconds: 250);
  static const Duration motionSlow = Duration(milliseconds: 300);
  static const Duration motionPage = Duration(milliseconds: 400);

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;

  // ─────────────────────────────────────────────
  // Z-INDEX
  // ─────────────────────────────────────────────

  static const int zIndexBase = 0;
  static const int zIndexDropdown = 100;
  static const int zIndexSticky = 500;
  static const int zIndexModal = 1000;
  static const int zIndexOverlay = 9999;

  // ─────────────────────────────────────────────
  // COMPONENT TOKENS (from persona)
  // ─────────────────────────────────────────────

  static double get cardPadding => 16;
  static double get cardRadius => _current.borderRadius;
  static double get cardBorderWidth => 1;

  static double get buttonPaddingH => 16;
  static double get buttonPaddingV => 8;
  static double get buttonRadius => _current.borderRadius;
  static double get buttonHeight => _current.ageGroup == AgeGroup.baby ? 56 : 40;
  static double get buttonHeightLarge => _current.ageGroup == AgeGroup.baby ? 64 : 48;

  static double get inputPaddingH => 12;
  static double get inputPaddingV => 8;
  static double get inputRadius => _current.borderRadius;
  static double get inputBorderWidth => 1;
  static double get inputHeight => _current.ageGroup == AgeGroup.baby ? 48 : 40;

  static double get badgePaddingH => 8;
  static double get badgePaddingV => 4;
  static double get badgeRadius => 999;

  static double get navHeight => 56;
  static double get navItemGap => 8;
}
