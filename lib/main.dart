import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: ECampusApp(),
    ),
  );
}

class ECampusApp extends StatelessWidget {
  const ECampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Campus',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E6FF2), // matches Figma style guide
      ),
      home: const _FirebaseCheckScreen(),
    );
  }
}

/// Temporary placeholder home screen — just proves Firebase is wired up.
/// Gets replaced by the real Splash/Auth flow in Phase 5.
class _FirebaseCheckScreen extends StatelessWidget {
  const _FirebaseCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 64),
            const SizedBox(height: 16),
            Text(
              'E-Campus project shell is live.\nFirebase connected: ${Firebase.apps.first.name}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}