import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.smart_toy_rounded,
      title: 'AI Chatbot',
      phaseNote: 'ChatGPT-powered assistant arrives in Phase 10.',
    );
  }
}