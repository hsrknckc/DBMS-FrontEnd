import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- Brand & Semantic Colors ---
  static const Color primary = Color(0xFF2563FF);
  static const Color primaryDark = Color(0xFF1418FF);
  static const Color accent = Color(0xFF00E5FF);
  static const Color violet = Color(0xFF7C3DFF);
  static const Color success = Color(0xFF01D6A3);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4D6D);

  // --- Light Mode ---
  static const Color background = Color(0xFFF3F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF8FBFF);
  static const Color border = Color(0xFFD8E3F0);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF66758E);
  static const Color textMuted = Color(0xFF98A6BA);

  // --- Dark Mode ---
  static const Color darkBackground = Color(0xFF050816);
  static const Color darkSurface = Color(0x9910182F);
  static const Color darkSurfaceElevated = Color(0xCC111936);
  static const Color darkBorder = Color(0x2FFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF7FAFF);
  static const Color darkTextSecondary = Color(0xFFCAD7F2);
  static const Color darkTextMuted = Color(0xFF8796B8);

  static const List<Color> brandGradient = [
    Color(0xFF2563EB),
    Color(0xFF14B8A6),
  ];

  static const List<Color> darkBrandGradient = [
    Color(0xFF00E5FF),
    Color(0xFF7C3DFF),
  ];
}
