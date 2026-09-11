import 'package:flutter/material.dart';
import '../constants/design_tokens.dart';

/// AppTheme built on superlogica DESIGN.md tokens
/// Follows: 4px grid, multi-layer shadow system, typography hierarchy, color roles
class AppTheme {
  AppTheme._();

  // ─── Color Aliases (backward compat) ───
  static Color get primaryDark => DesignTokens.background;
  static Color get secondaryDark => DesignTokens.surface;
  static Color get surfaceDark => DesignTokens.surfaceRaised;
  static Color get neonTeal => DesignTokens.accent;
  static Color get neonPurple => DesignTokens.accentSecondary;
  static Color get neonPink => DesignTokens.accentTertiary;
  static Color get textPrimary => DesignTokens.textPrimary;
  static Color get textSecondary => DesignTokens.textMuted;
  static Color get success => DesignTokens.success;
  static Color get warning => DesignTokens.warning;
  static Color get error => DesignTokens.danger;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: DesignTokens.accent,
      scaffoldBackgroundColor: DesignTokens.background,
      colorScheme: ColorScheme.dark(
        primary: DesignTokens.accent,
        secondary: DesignTokens.accentSecondary,
        surface: DesignTokens.surface,
        error: DesignTokens.danger,
        onPrimary: DesignTokens.background,
        onSecondary: DesignTokens.background,
        onSurface: DesignTokens.textPrimary,
        onError: DesignTokens.background,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeH3,
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamilyPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: DesignTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          side: BorderSide(
            color: DesignTokens.border,
            width: DesignTokens.cardBorderWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.accent,
          foregroundColor: DesignTokens.background,
          minimumSize: Size(0, DesignTokens.buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.buttonPaddingH,
            vertical: DesignTokens.buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          textStyle: TextStyle(
            fontSize: DesignTokens.fontSizeBodySmall,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.textMuted,
          textStyle: TextStyle(
            fontSize: DesignTokens.fontSizeBodySmall,
            fontWeight: DesignTokens.fontWeightMedium,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(
            color: DesignTokens.border,
            width: DesignTokens.inputBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(
            color: DesignTokens.border,
            width: DesignTokens.inputBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(
            color: DesignTokens.accent,
            width: DesignTokens.inputBorderWidth,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.inputPaddingH,
          vertical: DesignTokens.inputPaddingV,
        ),
        hintStyle: TextStyle(
          color: DesignTokens.textMuted,
          fontSize: DesignTokens.fontSizeBodySmall,
          fontFamily: DesignTokens.fontFamilyPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: DesignTokens.border,
        thickness: 1,
        space: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeH1,
          fontWeight: DesignTokens.fontWeightBold,
          fontFamily: DesignTokens.fontFamilyDisplay,
          height: DesignTokens.lineHeightHeading,
        ),
        headlineMedium: TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeH2,
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamilyDisplay,
          height: DesignTokens.lineHeightHeading,
        ),
        headlineSmall: TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeH3,
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamilyDisplay,
          height: DesignTokens.lineHeightHeading,
        ),
        bodyLarge: TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightRegular,
          fontFamily: DesignTokens.fontFamilyPrimary,
          height: DesignTokens.lineHeightBody,
        ),
        bodyMedium: TextStyle(
          color: DesignTokens.textMuted,
          fontSize: DesignTokens.fontSizeBodySmall,
          fontWeight: DesignTokens.fontWeightRegular,
          fontFamily: DesignTokens.fontFamilyPrimary,
          height: DesignTokens.lineHeightBody,
        ),
        bodySmall: TextStyle(
          color: DesignTokens.textMuted,
          fontSize: DesignTokens.fontSizeCaption,
          fontWeight: DesignTokens.fontWeightRegular,
          fontFamily: DesignTokens.fontFamilyPrimary,
          height: DesignTokens.lineHeightBody,
        ),
        labelLarge: TextStyle(
          color: DesignTokens.accent,
          fontSize: DesignTokens.fontSizeBodySmall,
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamilyPrimary,
        ),
        labelSmall: TextStyle(
          color: DesignTokens.textMuted,
          fontSize: DesignTokens.fontSizeCaption,
          fontWeight: DesignTokens.fontWeightMedium,
          fontFamily: DesignTokens.fontFamilyPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
