import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF0D47A1); // Deep blue
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color primaryDark = Color(0xFF002171);

  // Secondary and Accent Colors
  static const Color secondary = Color(0xFF00C853); // Green
  static const Color accentBlue = Color(0xFF26C6DA); // Cyan
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color ecoGreen = Color(0xFF00C853);
  static const Color alertRed = Color(0xFFEF4444);

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color white = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardBackgroundDark = Color(0xFF1E293B);
  static const Color borderGreyDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF334155);

  // Dark Mode Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);

  // Dark Mode Shadows
  static const Color shadowDark = Color(0x4D000000);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x29000000);
}
