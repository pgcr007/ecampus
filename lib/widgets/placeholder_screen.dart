import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared "not built yet" body used by every feature screen until its
/// real Phase (7-11) implementation replaces the content of that file.
/// Keeping this as a widget (not duplicated per screen) means each
/// screen file below only wires up its icon/title/phase number.
class PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String phaseNote;

  const PlaceholderScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.phaseNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phaseNote,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}