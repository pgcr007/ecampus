import 'package:flutter/material.dart';

/// Every possible destination in the app drawer. Not every role sees
/// every item — AppDrawer filters this list based on the user's role.
enum NavItem {
  home,
  announcements,
  library,
  bus,
  chat,
  chatbot,
  technews,
  manageUsers,
  profile,
}

extension NavItemX on NavItem {
  String get label {
    switch (this) {
      case NavItem.home:
        return 'Home';
      case NavItem.announcements:
        return 'Announcements';
      case NavItem.library:
        return 'E-Library';
      case NavItem.bus:
        return 'Bus Tracking';
      case NavItem.chat:
        return 'Chat';
      case NavItem.chatbot:
        return 'AI Chatbot';
      case NavItem.technews:
        return 'Tech News';
      case NavItem.manageUsers:
        return 'Manage Users';
      case NavItem.profile:
        return 'Profile';
    }
  }

  IconData get icon {
    switch (this) {
      case NavItem.home:
        return Icons.home_rounded;
      case NavItem.announcements:
        return Icons.campaign_rounded;
      case NavItem.library:
        return Icons.menu_book_rounded;
      case NavItem.bus:
        return Icons.directions_bus_rounded;
      case NavItem.chat:
        return Icons.chat_bubble_rounded;
      case NavItem.chatbot:
        return Icons.smart_toy_rounded;
      case NavItem.technews:
        return Icons.newspaper_rounded;
      case NavItem.manageUsers:
        return Icons.admin_panel_settings_rounded;
      case NavItem.profile:
        return Icons.person_rounded;
    }
  }
}