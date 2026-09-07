// lib/screens/admin/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart'; // allUsersProvider (Phase 9)
import '../../providers/user_management_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/user_management_tile.dart';

/// Teacher/Admin-only screen: search, filter, and manage every user's
/// role. Reachable only via the drawer's "Manage Users" item, which
/// RoleUtils.isTeacher already restricts to teachers — but the real
/// enforcement is the Firestore security rules on the `users` collection.
class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _roleFilter; // null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _roleChip(UserRole? role, String label) {
    final selected = _roleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _roleFilter = role),
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Future<void> _showChangeRoleSheet(UserModel user) async {
    UserRole selected = user.role;

    final result = await showModalBottomSheet<UserRole>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change role for ${user.name.isEmpty ? user.phone : user.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ...UserRole.values.map((role) {
                      return RadioListTile<UserRole>(
                        value: role,
                        groupValue: selected,
                        activeColor: AppColors.primary,
                        title: Text(role.label),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setSheetState(() => selected = v!),
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, selected),
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && result != user.role && mounted) {
      try {
        await ref.read(userServiceProvider).updateRole(uid: user.uid, newRole: result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.name.isEmpty ? user.phone : user.name} is now ${result.label}',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e')),
        );
      }
    }
  }

  Future<void> _confirmRemove(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove user?'),
        content: Text(
          '${user.name.isEmpty ? user.phone : user.name} will lose access to their profile '
          'and will need to complete registration again if they sign in. This does not '
          'delete their phone-based sign-in — only their app profile.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(userServiceProvider).removeUserProfile(user.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile removed')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final myUid = ref.watch(authStateChangesProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _roleChip(null, 'All'),
                  _roleChip(UserRole.student, 'Students'),
                  _roleChip(UserRole.classrep, 'Class Reps'),
                  _roleChip(UserRole.teacher, 'Teachers'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Something went wrong: $err')),
              data: (users) {
                var filtered = users.where((u) {
                  if (_roleFilter != null && u.role != _roleFilter) return false;
                  if (_searchQuery.isEmpty) return true;
                  return u.name.toLowerCase().contains(_searchQuery) ||
                      u.phone.toLowerCase().contains(_searchQuery);
                }).toList();

                filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return UserManagementTile(
                      user: user,
                      isCurrentUser: user.uid == myUid,
                      onChangeRole: () => _showChangeRoleSheet(user),
                      onRemove: () => _confirmRemove(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}