// lib/widgets/user_management_tile.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../utils/role_utils.dart';

class UserManagementTile extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback onChangeRole;
  final VoidCallback onRemove;

  const UserManagementTile({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.onChangeRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = RoleUtils.badgeColor(user.role);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: badgeColor.withOpacity(0.15),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name.isEmpty ? 'Unnamed user' : user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        const Text(
                          '(You)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (user.department.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.department,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrentUser)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'role') onChangeRole();
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'role',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz_rounded),
                      title: Text('Change role'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                      title: Text('Remove user', style: TextStyle(color: Colors.redAccent)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}