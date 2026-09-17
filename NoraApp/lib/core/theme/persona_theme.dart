import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../enums/age_group.dart';

/// Age-specific persona themes for Nora.
///
/// Each age group gets a unique color palette, mascot, and visual identity.
/// Nora adapts her appearance based on who she's talking to.
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
  final String fontFamily;
  final String displayFontFamily;
  final double borderRadius;
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
    required this.borderRadius,
    required this.isDark,
    required this.mascotAssetPath,
  });

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
  // BABY THEME (0-2)
  // Warm, bright, nurturing — like a nursery
  // ─────────────────────────────────────────────
  static const babyTheme = PersonaTheme(
    ageGroup: AgeGroup.baby,
    primary: Color(0xFFFF6B9D), // Warm pink
    primaryLight: Color(0xFFFFB3D1),
    secondary: Color(0xFFFFB347), // Sunny orange
    secondaryLight: Color(0xFFFFE0B2),
    accent: Color(0xFF7ED6DF), // Sky blue
    background: Color(0xFFFFF8E1), // Warm cream
    surface: Color(0xFFFFFFFF), // White
    surfaceRaised: Color(0xFFFFF3E0),
    textPrimary: Color(0xFF4A4A4A), // Soft dark
    textSecondary: Color(0xFF757575),
    textMuted: Color(0xFF9E9E9E),
    border: Color(0xFFE0E0E0),
    success: Color(0xFF66BB6A), // Gentle green
    warning: Color(0xFFFFCA28), // Soft yellow
    danger: Color(0xFFEF5350), // Soft red
    mascotName: 'Sunny',
    tagline: 'Let\'s learn and play!',
    fontFamily: 'Inter',
    displayFontFamily: 'Inter',
    borderRadius: 24,
    isDark: false,
    mascotAssetPath: 'assets/images/mascots/baby_star.svg',
  );

  // ─────────────────────────────────────────────
  // CHILD THEME (2-6)
  // Warm, bright, nurturing — like a kindergarten
  // ─────────────────────────────────────────────
  static const childTheme = PersonaTheme(
    ageGroup: AgeGroup.child,
    primary: Color(0xFFFF6B9D), // Warm pink
    primaryLight: Color(0xFFFFB3D1),
    secondary: Color(0xFFFFB347), // Sunny orange
    secondaryLight: Color(0xFFFFE0B2),
    accent: Color(0xFF7ED6DF), // Sky blue
    background: Color(0xFFFFF8E1), // Warm cream
    surface: Color(0xFFFFFFFF), // White
    surfaceRaised: Color(0xFFFFF3E0),
    textPrimary: Color(0xFF4A4A4A), // Soft dark
    textSecondary: Color(0xFF757575),
    textMuted: Color(0xFF9E9E9E),
    border: Color(0xFFE0E0E0),
    success: Color(0xFF66BB6A), // Gentle green
    warning: Color(0xFFFFCA28), // Soft yellow
    danger: Color(0xFFEF5350), // Soft red
    mascotName: 'Sunny',
    tagline: 'Let\'s learn and play!',
    fontFamily: 'Inter',
    displayFontFamily: 'Inter',
    borderRadius: 24,
    isDark: false,
    mascotAssetPath: 'assets/images/mascots/baby_star.svg',
  );

  // ─────────────────────────────────────────────
  // KID THEME (6-12)
  // Vibrant, playful, gamified — like a game world
  // ─────────────────────────────────────────────
  static const kidTheme = PersonaTheme(
    ageGroup: AgeGroup.kid,
    primary: Color(0xFF7C4DFF), // Vibrant purple
    primaryLight: Color(0xFFD1C4E9),
    secondary: Color(0xFF00BFA5), // Teal
    secondaryLight: Color(0xFFB2DFDB),
    accent: Color(0xFFFF6D00), // Orange
    background: Color(0xFFF5F5FF), // Light lavender
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF3E5F5),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF616161),
    textMuted: Color(0xFF757575),
    border: Color(0xFFE0E0E0),
    success: Color(0xFF00C853), // Bright green
    warning: Color(0xFFFFD600), // Yellow
    danger: Color(0xFFFF1744), // Red
    mascotName: 'Foxy',
    tagline: 'Adventure awaits!',
    fontFamily: 'Inter',
    displayFontFamily: 'Inter',
    borderRadius: 20,
    isDark: false,
    mascotAssetPath: 'assets/images/mascots/kid_fox.svg',
  );

  // ─────────────────────────────────────────────
  // TEEN THEME (12-18)
  // Cool, modern, trendy — dark with neon accents
  // ─────────────────────────────────────────────
  static const teenTheme = PersonaTheme(
    ageGroup: AgeGroup.teen,
    primary: Color(0xFF6C63FF), // Electric purple
    primaryLight: Color(0xFF9D97FF),
    secondary: Color(0xFF00D9FF), // Cyan
    secondaryLight: Color(0xFF80EAFF),
    accent: Color(0xFFFF006E), // Hot pink
    background: Color(0xFF0D0D1A), // Deep dark
    surface: Color(0xFF1A1A2E),
    surfaceRaised: Color(0xFF16213E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD0D0D0),
    textMuted: Color(0xFFB0B0B0),
    border: Color(0xFF2A2A3E),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFD600),
    danger: Color(0xFFFF5252),
    mascotName: 'Spark',
    tagline: 'Level up your life!',
    fontFamily: 'Inter',
    displayFontFamily: 'Inter',
    borderRadius: 16,
    isDark: true,
    mascotAssetPath: 'assets/images/mascots/teen_bolt.svg',
  );

  // ─────────────────────────────────────────────
  // ADULT THEME (18+)
  // Professional, calm, refined — superlogica dark
  // ─────────────────────────────────────────────
  static const adultTheme = PersonaTheme(
    ageGroup: AgeGroup.adult,
    primary: Color(0xFF2233FF), // Professional blue
    primaryLight: Color(0xFF7B8FFF),
    secondary: Color(0xFF9D4EDD), // Purple
    secondaryLight: Color(0xFFCE93D8),
    accent: Color(0xFF00D9FF), // Teal
    background: Color(0xFF1c1f24), // superlogica dark
    surface: Color(0xFF323b49),
    surfaceRaised: Color(0xFF252a38),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0BEC5),
    textMuted: Color(0xFF7789a3),
    border: Color(0xFF424f60),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFD600),
    danger: Color(0xFFd61d1e),
    mascotName: 'Nora',
    tagline: 'Focus. Learn. Grow.',
    fontFamily: 'Inter',
    displayFontFamily: 'Inter',
    borderRadius: 20,
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
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? background : Colors.white,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }
}
