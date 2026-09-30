import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // الألوان الأساسية الفاخرة
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);
  static const Color mediumGreen = Color(0xFF2D6A4F);
  static const Color lightBeige = Color(0xFFFBF8F1);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF252525);

  static final ThemeData lightTheme = _buildLightTheme();
  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final baseTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: lightBeige,
      appBarTheme: AppBarTheme(
        backgroundColor: lightBeige,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkGreen),
        titleTextStyle: GoogleFonts.cairo(
          color: darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: baseTextTheme.copyWith(
        bodyLarge: GoogleFonts.cairo(
          color: const Color(0xFF1A1A1A),
          fontSize: 17,
        ),
        bodyMedium: GoogleFonts.cairo(
          color: const Color(0xFF2E2E2E),
          fontSize: 15,
        ),
        titleLarge: GoogleFonts.cairo(
          color: darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.cairo(
          color: darkGreen,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: darkGreen,
        secondary: primaryGold,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFF1A1A1A),
      ),
      iconTheme: const IconThemeData(color: darkGreen),
      dividerTheme: DividerThemeData(
        color: primaryGold.withValues(alpha: 0.25),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightBeige,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryGold.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final baseTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: primaryGold),
        titleTextStyle: GoogleFonts.cairo(
          color: primaryGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        bodyLarge: GoogleFonts.cairo(color: lightBeige, fontSize: 17),
        bodyMedium: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 15),
        titleLarge: GoogleFonts.cairo(
          color: primaryGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.cairo(
          color: primaryGold,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: mediumGreen,
        surface: darkSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      iconTheme: const IconThemeData(color: primaryGold),
      dividerTheme: DividerThemeData(
        color: primaryGold.withValues(alpha: 0.25),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryGold.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
