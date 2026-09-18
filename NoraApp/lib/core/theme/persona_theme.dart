import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../enums/age_group.dart';

/// Age-specific persona themes for Nora.
///
/// Each age group gets its own color palette, mascot, and visual identity —
/// including its own typeface pairing and its own radius scale by role, not
/// just a single interpolated number. The goal is that a screenshot of any
/// one persona should be recognizable as Nora, but never mistaken for any
/// of the other four.
class PersonaTheme {
  final AgeGroup ageGroup;
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color secondaryLight;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
  final String mascotName;
  final String tagline;

  /// Body copy typeface — kept legible and quiet across every persona.
  final String fontFamily;

  /// Headline / display typeface — this is where each persona's character
  /// actually lives. Never the same value as [fontFamily].
  final String displayFontFamily;

  /// Radius for the loudest, most rounded surfaces: the mascot card, the
  /// primary CTA, big celebratory moments. This is where "friendly" is felt.
  final double radiusExpressive;

  /// Radius for everyday content surfaces: list cards, panels, sheets.
  final double radiusCard;

  /// Radius for small, dense controls: chips, badges, inline buttons.
  /// Deliberately tighter than [radiusCard] so the UI has a visible
  /// hierarchy instead of one rounding value stamped on everything.
  final double radiusChip;

  /// Radius for text inputs.
  final double radiusInput;

  final bool isDark;
  final String mascotAssetPath;

  const PersonaTheme({
    required this.ageGroup,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.secondaryLight,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.mascotName,
    required this.tagline,
    required this.fontFamily,
    required this.displayFontFamily,
    required this.radiusExpressive,
    required this.radiusCard,
    required this.radiusChip,
    required this.radiusInput,
    required this.isDark,
    required this.mascotAssetPath,
  });

  /// Backward-compatible single radius, kept for any call site that hasn't
  /// migrated to a role-specific radius yet. New code should prefer
  /// [radiusCard], [radiusChip], [radiusExpressive] or [radiusInput].
  double get borderRadius => radiusCard;

  /// Get the theme for a specific age group.
  factory PersonaTheme.forAgeGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return babyTheme;
      case AgeGroup.child:
        return childTheme;
      case AgeGroup.kid:
        return kidTheme;
      case AgeGroup.teen:
        return teenTheme;
      case AgeGroup.adult:
        return adultTheme;
    }
  }

  /// Build a mascot widget using the SVG asset.
  Widget buildMascotWidget({double size = 48, bool showGlow = false}) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        mascotAssetPath,
        width: size,
        height: size,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BABY THEME (0-2) — nursery
  // Comfortaa: soft, geometric, rounded terminals, calm — reads as gentle
  // rather than loud. Warm pink/cream, the gentlest palette of the five.
  // ─────────────────────────────────────────────
  static const babyTheme = PersonaTheme(
    ageGroup: AgeGroup.baby,
    primary: Color(0xFFFF8FB3), // Warm pink
    primaryLight: Color(0xFFFFC9DE),
    secondary: Color(0xFFFFC170), // Soft sunny orange
    secondaryLight: Color(0xFFFFE3B8),
    accent: Color(0xFF8FDDE3), // Sky blue
    background: Color(0xFFFFF8E9), // Warm cream
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFF1DC),
    textPrimary: Color(0xFF4A4A4A),
    textSecondary: Color(0xFF757575),
    textMuted: Color(0xFF9E9E9E),
    border: Color(0xFFEFE3D0),
    success: Color(0xFF7BC67F),
    warning: Color(0xFFFFCA5C),
    danger: Color(0xFFF07E76),
    mascotName: 'Sunny',
    tagline: 'Let\'s learn and play!',
    fontFamily: 'Inter',
    displayFontFamily: 'Comfortaa',
    radiusExpressive: 32,
    radiusCard: 24,
    radiusChip: 16,
    radiusInput: 20,
    isDark: false,
    mascotAssetPath: 'assets/images/mascots/baby_star.svg',
  );

  // ─────────────────────────────────────────────
  // CHILD THEME (2-6) — kindergarten
  // Same gentle Comfortaa family as Baby (developmentally adjacent, both
  // parent-managed with no free-form chat), but its own hue — teal and
  // sunny yellow rather than pink — and its own mascot, so the two ages
  // are never rendering as literally the same screen.
  // ─────────────────────────────────────────────
  static const childTheme = PersonaTheme(
    ageGroup: AgeGroup.child,
    primary: Color(0xFF3FBAAE), // Kindergarten teal
    primaryLight: Color(0xFFB0E6DF),
    secondary: Color(0xFFFFC94D), // Sunny yellow
    secondaryLight: Color(0xFFFFE8A8),
    accent: Color(0xFFFF9E7A), // Soft coral
    background: Color(0xFFF3FAF4), // Pale mint
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE8F6EE),
    textPrimary: Color(0xFF3E4A47),
    textSecondary: Color(0xFF6E7A77),
    textMuted: Color(0xFF9AA4A1),
    border: Color(0xFFDCEEE5),
    success: Color(0xFF5FB86A),
    warning: Color(0xFFFFC94D),
    danger: Color(0xFFF0847A),
    mascotName: 'Willow',
    tagline: 'Time to explore!',
    fontFamily: 'Inter',
    displayFontFamily: 'Comfortaa',
    radiusExpressive: 32,
    radiusCard: 22,
    radiusChip: 16,
    radiusInput: 18,
    isDark: false,
    mascotAssetPath: 'assets/images/mascots/nora_cat.svg',
  );

  // ─────────────────────────────────────────────
  // KID THEME (6-12) — adventure / game world
  // Baloo 2: chunky, bold, high-contrast weight jumps — the one persona
  // allowed to feel like a game HUD. Purple/teal/orange kept, but the
  // typography now does the "fun" work instead of just the color.
  // ─────────────────────────────────────────────
  static const kidTheme = PersonaTheme(
    ageGroup: AgeGroup.kid,
    primary: Color(0xFF7C4DFF),
    primaryLight: Color(0xFFD1C4E9),
    secondary: Color(0xFF00BFA5),
    secondaryLight: Color(0xFFB2DFDB),
    accent: Color(0xFFFF6D00),
    background: Color(0xFFF5F5FF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF3E5F5),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF616161),
    textMuted: Color(0xFF757575),
    border: Color(0xFFE0E0E0),
    success: Color(0xFF00C853),
    warning: Color(0xFFFFD600),
    danger: Color(0xFFFF1744),
    mascotName: 'Foxy',
    tagline: 'Adventure awaits!',
    fontFamily: 'Inter',
    displayFontFamily: 'Baloo2',
    radiusExpressive: 28,
    radiusCard: 20,
    radiusChip: 14,
    radiusInput: 16,
    isDark: false,
    mascotAssetPath: 'assets/images/mascots/kid_fox.svg',
  );

  // ─────────────────────────────────────────────
  // TEEN THEME (12-18) — cool, modern
  // Space Grotesk: geometric, confident, contemporary — the typeface that
  // reads as "made in 2026" without leaning on a neon triad to do it.
  // Collapsed from three competing accent hues to two, so the dark surface
  // reads as considered rather than "dark mode + whatever accent was left."
  // ─────────────────────────────────────────────
  static const teenTheme = PersonaTheme(
    ageGroup: AgeGroup.teen,
    primary: Color(0xFF6C63FF), // Electric indigo
    primaryLight: Color(0xFF9D97FF),
    secondary: Color(0xFF00D9FF), // Cyan, used sparingly as the one accent
    secondaryLight: Color(0xFF80EAFF),
    accent: Color(0xFF00D9FF),
    background: Color(0xFF0D0D1A),
    surface: Color(0xFF17172B),
    surfaceRaised: Color(0xFF1F1F38),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC7C7DA),
    textMuted: Color(0xFF8B8BA3),
    border: Color(0xFF2C2C46),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFD600),
    danger: Color(0xFFFF5C7A),
    mascotName: 'Spark',
    tagline: 'Level up your life!',
    fontFamily: 'Inter',
    displayFontFamily: 'SpaceGrotesk',
    radiusExpressive: 24,
    radiusCard: 16,
    radiusChip: 10,
    radiusInput: 12,
    isDark: true,
    mascotAssetPath: 'assets/images/mascots/teen_bolt.svg',
  );

  // ─────────────────────────────────────────────
  // ADULT THEME (18+) — calm, considered focus
  // Previously a B2B dashboard palette (comment in source literally read
  // "superlogica dark"). Replaced with a warm, low-saturation neutral and
  // a single confident sage-teal accent — closer to what the calmest
  // competitors (Opal, Clearspace) use than a fintech admin panel.
  // Lora as the display face: a serif is genuinely unusual in this
  // category and signals "considered space," not "productivity tool."
  // ─────────────────────────────────────────────
  static const adultTheme = PersonaTheme(
    ageGroup: AgeGroup.adult,
    primary: Color(0xFF00C896), // Neptun Green — active states, CTAs, success
    primaryLight: Color(0xFF33D4A8),
    secondary: Color(0xFF7B61FF), // Purple Neon — AI features, badges
    secondaryLight: Color(0xFF9B85FF),
    accent: Color(0xFF00C896),
    background: Color(0xFF0A0E1A), // Deep dark — low eye strain
    surface: Color(0xFF141927), // Card surfaces
    surfaceRaised: Color(0xFF1C2235), // Elevated cards
    textPrimary: Color(0xFFE8ECF4), // High-contrast light
    textSecondary: Color(0xFF8A92A6), // Muted blue-gray
    textMuted: Color(0xFF4E5670),
    border: Color(0xFF1E2740), // Subtle blue-gray border
    success: Color(0xFF00C896),
    warning: Color(0xFFD4A359), // Gold/Amber — streaks, achievements
    danger: Color(0xFFE05252),
    mascotName: 'Nora',
    tagline: 'Focus. Learn. Grow.',
    fontFamily: 'Inter',
    displayFontFamily: 'Lora',
    radiusExpressive: 20,
    radiusCard: 14,
    radiusChip: 8,
    radiusInput: 10,
    isDark: true,
    mascotAssetPath: 'assets/images/mascots/adult_brain.svg',
  );

  /// Convert to ThemeData for MaterialApp.
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
        onPrimary: isDark ? background : Colors.white,
        onSecondary: isDark ? background : Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: displayFontFamily,
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          // Dark personas lean on a visible border for elevation instead
          // of a drop shadow that was never designed for a dark surface.
          side: BorderSide(color: border, width: isDark ? 1 : 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? background : Colors.white,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusChip),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: displayFontFamily,
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: displayFontFamily,
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontFamily: displayFontFamily,
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }
}
