import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nav_item.dart';
import '../../models/user_model.dart';
import '../../providers/nav_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/role_utils.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final UserModel user;
  const HomeDashboardScreen({super.key, required this.user});

  List<NavItem> _quickLinksForRole(UserRole role) {
    final links = <NavItem>[NavItem.library, NavItem.bus, NavItem.chat, NavItem.chatbot, NavItem.technews];
    if (RoleUtils.isClassRepOrAbove(role)) links.insert(0, NavItem.announcements);
    if (RoleUtils.isTeacher(role)) links.add(NavItem.manageUsers);
    return links;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickLinks = _quickLinksForRole(user.role);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user.name.split(' ').first} 👋',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            user.role.label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: quickLinks.map((item) {
              return _QuickLinkCard(
                item: item,
                onTap: () => ref.read(selectedNavItemProvider.notifier).state = item,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final NavItem item;
  final VoidCallback onTap;

  const _QuickLinkCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}