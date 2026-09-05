import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class BusScreen extends StatelessWidget {
  const BusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.directions_bus_rounded,
      title: 'Bus Tracking',
      phaseNote: 'Live Google Maps bus tracking arrives in Phase 8.',
    );
  }
}