import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/role_utils.dart';
import '../../widgets/announcement_card.dart';
import 'add_announcement_screen.dart';

/// Readable by every role; the "Post" FAB only renders for Class Rep /
/// Teacher, per RBAC. Firestore rules enforce the same restriction
/// server-side (see the Phase 9 rules block).
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final canPost = profileAsync.valueOrNull != null &&
        RoleUtils.isClassRepOrAbove(profileAsync.valueOrNull!.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load announcements: $err')),
        data: (announcements) {
          if (announcements.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No announcements yet.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: announcements.length,
            itemBuilder: (context, index) => AnnouncementCard(announcement: announcements[index]),
          );
        },
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Post', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAnnouncementScreen()),
              ),
            )
          : null,
    );
  }
}