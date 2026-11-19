import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color navy = Color(0xFF0B1D33);
  static const Color navyLight = Color(0xFF123B65);
  static const Color blue = Color(0xFF2878C8);
  static const Color electricBlue = Color(0xFF50B8FF);
  static const Color gold = Color(0xFFD5AD65);

  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF172B42);
  static const Color textMuted = Color(0xFF75869A);
  static const Color border = Color(0xFFE5EBF2);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navyLight,
        primary: navyLight,
        secondary: gold,
        surface: surface,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textMuted,
          height: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 8,
        height: 70,
        indicatorColor: const Color(0xFFE7F1FC),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? navyLight
                : textMuted,
          );
        }),
      ),
    );
  }
}
