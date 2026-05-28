import 'package:flutter/material.dart';

class AppTheme {
  // ─── Color Palette ────────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF050A18);
  static const Color bgCard = Color(0xFF0D1B2E);
  static const Color bgCardLight = Color(0xFF112240);

  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryCyan = Color(0xFF00D4FF);
  static const Color accentCyan = Color(0xFF00F5FF);
  static const Color accentGlow = Color(0xFF0AEFFF);

  static const Color emergencyRed = Color(0xFFFF1744);
  static const Color emergencyOrange = Color(0xFFFF6D00);
  static const Color warningYellow = Color(0xFFFFD600);
  static const Color safeGreen = Color(0xFF00E676);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8899AA);
  static const Color textMuted = Color(0xFF4A6080);
  static const Color textCyan = Color(0xFF00D4FF);

  static const Color divider = Color(0xFF1A2A40);
  static const Color glassBorder = Color(0xFF1E3A5F);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF050A18), Color(0xFF0A1628), Color(0xFF050F20)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066FF), Color(0xFF00D4FF)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF1744), Color(0xFFFF6D00)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B2E), Color(0xFF112240)],
  );

  static const LinearGradient safeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
  );

  // ─── Typography ───────────────────────────────────────────────────────────
  static const String fontPoppins = 'Poppins';
  static const String fontInter = 'Inter';

  static TextStyle get headingXL => const TextStyle(
        fontFamily: fontPoppins,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headingLG => const TextStyle(
        fontFamily: fontPoppins,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get headingMD => const TextStyle(
        fontFamily: fontPoppins,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get headingSM => const TextStyle(
        fontFamily: fontPoppins,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLG => const TextStyle(
        fontFamily: fontInter,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodyMD => const TextStyle(
        fontFamily: fontInter,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get bodySM => const TextStyle(
        fontFamily: fontInter,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  static TextStyle get label => const TextStyle(
        fontFamily: fontInter,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.8,
      );

  static TextStyle get numericLG => const TextStyle(
        fontFamily: fontPoppins,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -1,
      );

  static TextStyle get numericMD => const TextStyle(
        fontFamily: fontPoppins,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryCyan,
        letterSpacing: -0.5,
      );

  // ─── Theme Data ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryCyan,
        surface: bgCard,
        error: emergencyRed,
      ),
      fontFamily: fontPoppins,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontPoppins,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: const CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: glassBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontFamily: fontInter),
        labelStyle: const TextStyle(color: textSecondary, fontFamily: fontInter),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: fontPoppins,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryCyan,
          textStyle: const TextStyle(
            fontFamily: fontInter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerColor: divider,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F4FF),
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryCyan,
      ),
      fontFamily: fontPoppins,
    );
  }
}
