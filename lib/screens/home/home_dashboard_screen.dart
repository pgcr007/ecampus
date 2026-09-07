// lib/screens/home/home_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/announcement_model.dart';
import '../../models/nav_item.dart';
import '../../models/user_model.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/tech_news_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/role_utils.dart';
import '../../utils/time_utils.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final UserModel user;
  const HomeDashboardScreen({super.key, required this.user});

  List<NavItem> _quickLinksForRole(UserRole role) {
    final links = <NavItem>[
      NavItem.library,
      NavItem.bus,
      NavItem.chat,
      NavItem.chatbot,
      NavItem.technews,
    ];
    if (RoleUtils.isClassRepOrAbove(role)) links.insert(0, NavItem.announcements);
    if (RoleUtils.isTeacher(role)) links.add(NavItem.manageUsers);
    return links;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickLinks = _quickLinksForRole(user.role);
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final booksAsync = ref.watch(booksStreamProvider);
    final techNewsAsync = ref.watch(techNewsStreamProvider(user.department));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroHeader(user: user),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.campaign_rounded,
                  label: 'Announcements',
                  value: announcementsAsync.valueOrNull?.length,
                  color: AppColors.accentCoral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  icon: Icons.menu_book_rounded,
                  label: 'Library',
                  value: booksAsync.valueOrNull?.length,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  icon: Icons.newspaper_rounded,
                  label: 'Tech News',
                  value: techNewsAsync.valueOrNull?.length,
                  color: AppColors.teacherBadge,
                ),
              ),
            ],
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
                accent: item.accentColor,
                onTap: () => ref.read(selectedNavItemProvider.notifier).state = item,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Announcements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              if ((announcementsAsync.valueOrNull ?? []).isNotEmpty)
                TextButton(
                  onPressed: () =>
                      ref.read(selectedNavItemProvider.notifier).state = NavItem.announcements,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          announcementsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const _EmptyNote(text: "Couldn't load announcements"),
            data: (list) {
              if (list.isEmpty) {
                return const _EmptyNote(text: 'No announcements yet. Check back soon!');
              }
              return Column(
                children: list.take(2).map((a) => _AnnouncementPreviewCard(announcement: a)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Gradient hero card: time-based greeting, role + department, avatar.
class _HeroHeader extends StatelessWidget {
  final UserModel user;
  const _HeroHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.trim().isEmpty ? 'there' : user.name.trim().split(' ').first;
    final badgeColor = RoleUtils.badgeColor(user.role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1B4FD6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(Icons.school_rounded, size: 120, color: Colors.white.withOpacity(0.08)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${TimeUtils.greeting()}, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (user.department.isNotEmpty)
                          Text(
                            user.department,
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small live-count tile used in the stats row under the hero header.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value == null ? '--' : '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// One tile in the "Quick Access" grid — tinted icon circle per feature.
class _QuickLinkCard extends StatelessWidget {
  final NavItem item;
  final Color accent;
  final VoidCallback onTap;

  const _QuickLinkCard({required this.item, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, size: 24, color: accent),
              ),
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

/// Compact preview card for the "Recent Announcements" section.
class _AnnouncementPreviewCard extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementPreviewCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentCoral.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded, color: AppColors.accentCoral, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title.isEmpty ? '(Untitled)' : announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  announcement.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  TimeUtils.fullTimestamp(announcement.timestamp),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty/error placeholder for the announcements section.
class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}