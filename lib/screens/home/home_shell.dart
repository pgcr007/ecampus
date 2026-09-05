import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nav_item.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../announcements/announcements_screen.dart';
import '../admin/manage_users_screen.dart';
import '../bus/bus_screen.dart';
import '../chat/chat_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../technews/technews_screen.dart';
import 'home_dashboard_screen.dart';

/// Root authenticated shell. AuthGate hands off here once a Firestore
/// user profile exists. Everything below is one Scaffold with a
/// role-aware Drawer (Phase 6) — feature bodies get filled in properly
/// in Phases 7-11, they're placeholders for now.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  Widget _bodyFor(NavItem item, UserModel user) {
    switch (item) {
      case NavItem.home:
        return HomeDashboardScreen(user: user);
      case NavItem.announcements:
        return const AnnouncementsScreen();
      case NavItem.library:
        return const LibraryScreen();
      case NavItem.bus:
        return const BusScreen();
      case NavItem.chat:
        return const ChatScreen();
      case NavItem.chatbot:
        return const ChatbotScreen();
      case NavItem.technews:
        return const TechNewsScreen();
      case NavItem.manageUsers:
        return const ManageUsersScreen();
      case NavItem.profile:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final selected = ref.watch(selectedNavItemProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Something went wrong: $err')),
      ),
      data: (user) {
        if (user == null) {
          // Should be momentary — AuthGate will swap to CompleteProfileScreen.
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(selected.label),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          drawer: AppDrawer(user: user),
          body: _bodyFor(selected, user),
        );
      },
    );
  }
}