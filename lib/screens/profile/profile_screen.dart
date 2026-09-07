// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/department_utils.dart';
import '../../utils/role_utils.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // NEW (Phase 11) — dialog to set/change department. Needed because
  // accounts created before Phase 11 have no department field at all.
  Future<void> _editDepartment(BuildContext context, WidgetRef ref, UserModel user) async {
    String? selected = user.department.isNotEmpty ? user.department : null;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Set Department'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: DepartmentUtils.all
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (value) => setState(() => selected = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: selected == null ? null : () => Navigator.pop(ctx, selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(authServiceProvider).updateDepartment(uid: user.uid, department: result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Department set to $result')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: RoleUtils.badgeColor(user.role),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  user.role.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.phone_rounded, color: AppColors.primary),
                  title: const Text('Phone'),
                  subtitle: Text(user.phone),
                ),
              ),
              const SizedBox(height: 12),
              // NEW (Phase 11) — department row, tap to set/change.
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.school_rounded, color: AppColors.primary),
                  title: const Text('Department'),
                  subtitle: Text(
                    user.department.isNotEmpty ? user.department : 'Not set — tap to choose',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editDepartment(context, ref, user),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}