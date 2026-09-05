import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Manage Users',
      phaseNote: 'Role management tools get built out during Phase 12 (Integration & Testing).',
    );
  }
}