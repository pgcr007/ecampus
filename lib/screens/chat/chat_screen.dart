import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.chat_bubble_rounded,
      title: 'Chat',
      phaseNote: 'Real-time messaging arrives in Phase 9.',
    );
  }
}