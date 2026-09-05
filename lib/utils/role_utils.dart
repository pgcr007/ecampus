import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';

/// Small helpers on top of UserRole for badge colors. Display names
/// come straight from `UserRole.label` (defined in user_model.dart) —
/// no need to duplicate that switch here.
class RoleUtils {
  RoleUtils._();

  static Color badgeColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return AppColors.studentBadge;
      case UserRole.classrep:
        return AppColors.classrepBadge;
      case UserRole.teacher:
        return AppColors.teacherBadge;
    }
  }

  static bool isClassRepOrAbove(UserRole role) =>
      role == UserRole.classrep || role == UserRole.teacher;

  static bool isTeacher(UserRole role) => role == UserRole.teacher;
}