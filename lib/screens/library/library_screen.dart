import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.menu_book_rounded,
      title: 'E-Library',
      phaseNote: 'Book listing, search, and PDF viewing arrive in Phase 7.',
    );
  }
}