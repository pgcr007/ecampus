import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class TechNewsScreen extends StatelessWidget {
  const TechNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.newspaper_rounded,
      title: 'Tech News',
      phaseNote: 'Department-wise tech news feed arrives in Phase 11.',
    );
  }
}