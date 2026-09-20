import 'package:flutter/material.dart';
import '../enums/age_group.dart';
import '../theme/persona_theme.dart';
import '../../providers/design_tokens_provider.dart';

/// Design Tokens that adapt based on the current PersonaTheme.
///
/// All UI components reference these tokens. When the user's age group changes,
/// the tokens update automatically and the entire UI adapts.
///
/// Tokens now delegate to [DesignTokensScope], which is updated by
/// [DesignTokensProvider]. Legacy [init] calls still work but should migrate
/// to `Provider.of<DesignTokensProvider>(context).setPersona(theme)`.
class DesignTokens {
  DesignTokens._();

  // ─────────────────────────────────────────────
  // CURRENT PERSONA (delegates to scope)
  // ─────────────────────────────────────────────

  /// Legacy init — prefer [DesignTokensProvider.setPersona] instead.
  static void init(PersonaTheme theme) {
    DesignTokensScope.init(theme);
  }

  /// Get current persona.
  static PersonaTheme get current => DesignTokensScope.current;

  /// Get current age group.
  static AgeGroup get ageGroup => DesignTokensScope.current.ageGroup;

  // ─────────────────────────────────────────────
  // COLOR ROLES (from persona)
  // ─────────────────────────────────────────────

  static Color get background => DesignTokensScope.current.background;
  static Color get surface => DesignTokensScope.current.surface;
  static Color get surfaceRaised => DesignTokensScope.current.surfaceRaised;
  static Color get textPrimary => DesignTokensScope.current.textPrimary;
  static Color get textSecondary => DesignTokensScope.current.textSecondary;
  static Color get textMuted => DesignTokensScope.current.textMuted;
  static Color get border => DesignTokensScope.current.border;
  static Color get accent => DesignTokensScope.current.primary;
  static Color get primary => DesignTokensScope.current.primary;
  static Color get accentLight => DesignTokensScope.current.primaryLight;
  static Color get accentSecondary => DesignTokensScope.current.secondary;
  static Color get accentSecondaryLight => DesignTokensScope.current.secondaryLight;
  static Color get accentTertiary => DesignTokensScope.current.accent;
  static Color get success => DesignTokensScope.current.success;
  static Color get warning => DesignTokensScope.current.warning;
  static Color get danger => DesignTokensScope.current.danger;
  static Color get error => DesignTokensScope.current.danger;

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
  static double get radius20 => DesignTokensScope.current.radiusCard;
  static double get radius24 => 24;
  static double get radius40 => 40;
  static double get radiusRound => 999;

  /// The persona's most rounded, most "friendly" radius — for mascot
  /// cards, hero CTAs, and celebratory moments. Deliberately not used
  /// for everyday content surfaces; see [radius20] / [cardRadius] for that.
  static double get radiusExpressive => DesignTokensScope.current.radiusExpressive;

  // ─────────────────────────────────────────────
  // TYPOGRAPHY
  // ─────────────────────────────────────────────

  static String get fontFamilyPrimary => DesignTokensScope.current.fontFamily;
  static String get fontFamilyDisplay => DesignTokensScope.current.displayFontFamily;

  static const double fontSizeH1 = 28;
  static const double fontSizeH2 = 24;
  static const double fontSizeH3 = 20;
  static const double fontSizeBody = 16;
  static const double fontSizeBodySmall = 14;
  static const double fontSizeCaption = 12;

  static const double fontSizeDisplayLarge = 64;
  static const double fontSizeDisplayMedium = 56;
  static const double fontSizeDisplaySmall = 48;
  static const double fontSizeTimer = 56;
  static const double fontSizeTitleLarge = 32;
  static const double fontSizeTitleMedium = 22;
  static const double fontSizeSubhead = 18;
  static const double fontSizeBodyMedium = 15;
  static const double fontSizeSmall = 13;
  static const double fontSizeExtraSmall = 11;
  static const double fontSizeTiny = 10;
  static const double fontSizeMicro = 9;
  static const double fontSizeNano = 8;

  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightRegular = FontWeight.w400;

  static const double lineHeightHeading = 1.2;
  static const double lineHeightBody = 1.5;

  // ─────────────────────────────────────────────
  // SEMANTIC COLORS (static — app-level, not persona-specific)
  // ─────────────────────────────────────────────

  static const Color brandPink = Color(0xFFE91E63);
  static const Color brandPurple = Color(0xFF9C27B0);
  static const Color brandDeepOrange = Color(0xFFFF5722);
  static const Color brandGreen = Color(0xFF4CAF50);
  static const Color brandBlue = Color(0xFF2196F3);
  static const Color brandTeal = Color(0xFF00BCD4);
  static const Color brandOrange = Color(0xFFFF9800);
  static const Color brandIndigo = Color(0xFF3F51B5);
  static const Color brandBrown = Color(0xFF795548);

  static const Color categorySocial = brandPink;
  static const Color categoryEntertainment = brandPurple;
  static const Color categoryProductivity = brandDeepOrange;
  static const Color categoryGames = brandGreen;
  static const Color categoryEducation = brandBlue;
  static const Color categoryHealth = brandTeal;
  static const Color categoryFinance = brandOrange;
  static const Color categoryNews = Color(0xFF4CAF50);
  static const Color categoryShopping = brandIndigo;
  static const Color categoryCreativity = brandPink;
  static const Color categoryCommunication = brandBrown;

  static const Color darkBackground = Color(0xFF1E1F36);
  static const Color darkSurface = Color(0xFF1A1B2E);

  // ─────────────────────────────────────────────
  // SHADOW / ELEVATION (adapt to light/dark persona)
  // ─────────────────────────────────────────────

  static List<BoxShadow> get shadowFlat => [];

  static List<BoxShadow> get shadowRaised {
    if (DesignTokensScope.current.isDark) {
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
    if (DesignTokensScope.current.isDark) {
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
      color: DesignTokensScope.current.isDark
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
  static double get cardRadius => DesignTokensScope.current.radiusCard;
  static double get cardBorderWidth => 1;

  static double get buttonPaddingH => 16;
  static double get buttonPaddingV => 8;
  // Buttons sit in the "dense control" tier, not the card tier — this is
  // what makes a button read as a different kind of surface than the
  // card it sits inside, instead of the same rounding stamped on both.
  static double get buttonRadius => DesignTokensScope.current.radiusChip;
  static double get buttonHeight => DesignTokensScope.current.ageGroup == AgeGroup.baby ? 56 : 40;
  static double get buttonHeightLarge => DesignTokensScope.current.ageGroup == AgeGroup.baby ? 64 : 48;

  static double get inputPaddingH => 12;
  static double get inputPaddingV => 8;
  static double get inputRadius => DesignTokensScope.current.radiusInput;
  static double get inputBorderWidth => 1;
  static double get inputHeight => DesignTokensScope.current.ageGroup == AgeGroup.baby ? 48 : 40;

  static double get badgePaddingH => 8;
  static double get badgePaddingV => 4;
  static double get badgeRadius => 999;

  static double get navHeight => 56;
  static double get navItemGap => 8;
}
