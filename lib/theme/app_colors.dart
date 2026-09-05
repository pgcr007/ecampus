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
}