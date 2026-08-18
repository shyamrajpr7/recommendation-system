import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const bgColor = Color(0xFFF8F9FC);
    const surfaceColor = Color(0xFFFFFFFF);
    const surfaceColor2 = Color(0xFFF1F3F8);
    const surfaceColor3 = Color(0xFFE8ECF4);
    const borderColor = Color(0xFFD8DEF0);
    const borderSoftColor = Color(0xFFE2E7F0);
    const textColor = Color(0xFF0F172A);
    const textSecColor = Color(0xFF475569);
    const mutedColor = Color(0xFF94A3B8);
    const muted2Color = Color(0xFFCBD5E1);

    const accent1 = Color(0xFF0284C7);
    const accent2 = Color(0xFF6366F1);
    const accent3 = Color(0xFF7C3AED);
    const error = Color(0xFFDC2626);

    final colorScheme = ColorScheme.light(
      primary: accent1,
      primaryContainer: accent2,
      secondary: accent3,
      surface: surfaceColor,
      error: error,
      onPrimary: Colors.white,
      onSurface: textColor,
    );

    return _buildTheme(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBg: bgColor,
      surface: surfaceColor,
      surface2: surfaceColor2,
      surface3: surfaceColor3,
      border: borderColor,
      borderSoft: borderSoftColor,
      text: textColor,
      textSec: textSecColor,
      muted: mutedColor,
      muted2: muted2Color,
      accent1: accent1,
      accent2: accent2,
      accent3: accent3,
      errorColor: error,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.accent1,
      primaryContainer: AppColors.accent2,
      secondary: AppColors.accent3,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.text,
    );

    return _buildTheme(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBg: AppColors.background,
      surface: AppColors.surface,
      surface2: AppColors.surface2,
      surface3: AppColors.surface3,
      border: AppColors.border,
      borderSoft: AppColors.borderSoft,
      text: AppColors.text,
      textSec: AppColors.textSecondary,
      muted: AppColors.muted,
      muted2: AppColors.muted2,
      accent1: AppColors.accent1,
      accent2: AppColors.accent2,
      accent3: AppColors.accent3,
      errorColor: AppColors.error,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color surface,
    required Color surface2,
    required Color surface3,
    required Color border,
    required Color borderSoft,
    required Color text,
    required Color textSec,
    required Color muted,
    required Color muted2,
    required Color accent1,
    required Color accent2,
    required Color accent3,
    required Color errorColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderSoft),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent1, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: muted2, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent1,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent1,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: borderSoft, thickness: 1, space: 0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface3,
        contentTextStyle: GoogleFonts.inter(color: text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
