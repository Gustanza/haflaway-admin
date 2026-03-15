import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GusTheme {
  // ─── Color Palette ─────────────────────────────────────────────────────────
  static const obsidian = Color(0xFF0A0A0F);
  static const surface = Color(0xFF111118);
  static const surface2 = Color(0xFF18181F);
  static const surface3 = Color(0xFF1E1E28);

  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96B);
  static const goldDim = Color(0xFF8A6A28);
  static const glassBorder = Color(0x26C9A84C);

  static const textPrimary = Color(0xFFF0ECE2);
  static const textMuted = Color(0xFF8A8578);
  static const textDim = Color(0xFF4A4840);

  static const green = Color(0xFF2ECC8A);
  static const greenBg = Color(0x142ECC8A);
  static const greenBorder = Color(0x332ECC8A);

  static const orange = Color(0xFFE8924B);
  static const orangeBg = Color(0x14E8924B);
  static const orangeBorder = Color(0x33E8924B);

  static const red = Color(0xFFE85555);
  static const redBg = Color(0x14E85555);
  static const redBorder = Color(0x33E85555);

  // ─── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headerTextTheme = GoogleFonts.cormorantGaramondTextTheme();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      primaryColor: gold,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headerTextTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: headerTextTheme.displayMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: headerTextTheme.displaySmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: headerTextTheme.headlineLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: headerTextTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: headerTextTheme.headlineSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: headerTextTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 24,
        ),
        titleMedium: headerTextTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: headerTextTheme.titleSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textMuted),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textMuted),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: obsidian,
        elevation: 0,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: obsidian,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      dividerTheme: const DividerThemeData(color: glassBorder, thickness: 0.5),
    );
  }
}
