import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

/// Temporary role-aware home screen — replaced by the real drawer
/// navigation shell in Phase 6.
class HomePlaceholderScreen extends ConsumerWidget {
  final UserModel user;

  const HomePlaceholderScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Campus'),
        backgroundColor: const Color(0xFF2E6FF2),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 64),
            const SizedBox(height: 16),
            Text('Welcome, ${user.name}!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Role: ${user.role.label}'),
            Text('Phone: ${user.phone}'),
            const SizedBox(height: 24),
            const Text(
              'Auth + RBAC complete.\nDrawer navigation arrives in Phase 6.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}