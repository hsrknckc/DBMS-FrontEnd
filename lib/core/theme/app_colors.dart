import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- Brand & Semantic Colors ---
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF14B8A6);
  static const Color violet = Color(0xFF7C3AED);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // --- Light Mode ---
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFDCE3EC);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // --- Dark Mode ---
  static const Color darkBackground = Color(0xFF0A0F1C);
  static const Color darkSurface = Color(0xFF0E1117);
  static const Color darkSurfaceElevated = Color(0xFF171A21);
  static const Color darkBorder = Color(0xFF2A2F3A);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  static const List<Color> brandGradient = [
    Color(0xFF2563EB),
    Color(0xFF14B8A6),
  ];

  static const List<Color> darkBrandGradient = [
    Color(0xFFF59E0B),
    Color(0xFF10B981),
  ];
}
