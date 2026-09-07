import 'package:flutter/material.dart';

/// Central place for the Figma style-guide colors so every screen
/// stays visually consistent without repeating hex codes everywhere.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E6FF2);
  static const Color secondary = Color(0xFF1D9E75);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6B7280);

  // Role badge colors
  static const Color studentBadge = primary;
  static const Color classrepBadge = secondary;
  static const Color teacherBadge = Color(0xFFE0912B);

  // Dashboard quick-access accents — one distinct color per feature so
  // the "Quick Access" grid reads as a set of destinations, not a wall
  // of identical blue tiles.
  static const Color accentCoral = Color(0xFFEF5DA8);
  static const Color accentTeal = Color(0xFF0EA5A5);
  static const Color accentPurple = Color(0xFF7C5CFC);
  static const Color accentIndigo = Color(0xFF3949AB);
}