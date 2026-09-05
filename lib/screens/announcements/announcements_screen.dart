import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.campaign_rounded,
      title: 'Announcements',
      phaseNote: 'Class-rep announcement posting lands alongside the Chat module in Phase 9.',
    );
  }
}