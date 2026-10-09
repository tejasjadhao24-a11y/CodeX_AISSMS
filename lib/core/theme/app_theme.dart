import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadowLight,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shadowColor: AppColors.primary.withValues(alpha: 0.1),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textMuted,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accentBlue,
        surface: AppColors.surface,
        error: AppColors.alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: AppColors.white),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textMutedDark,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 2,
        shadowColor: AppColors.shadowDark,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shadowColor: AppColors.shadowDark,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: AppColors.cardBackgroundDark,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGreyDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGreyDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondaryDark),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMutedDark),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentBlue,
        surface: AppColors.surfaceDark,
        error: AppColors.alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.white,
      ),
    );
  }
}
