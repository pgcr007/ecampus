import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../auth/complete_profile_screen.dart';
import '../auth/phone_entry_screen.dart';
import '../home/home_shell.dart';

/// Root widget that decides which screen to show based on auth + profile
/// state. This is the single source of truth for routing in the app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const _SplashLoader(),
      error: (err, _) => _SplashError(message: err.toString()),
      data: (user) {
        if (user == null) {
          return const PhoneEntryScreen();
        }

        final profileState = ref.watch(userProfileProvider);
        return profileState.when(
          loading: () => const _SplashLoader(),
          error: (err, _) => _SplashError(message: err.toString()),
          data: (profile) {
  if (profile == null) {
    return CompleteProfileScreen(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
    );
  }
  return const HomeShell();
},
        );
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SplashError extends StatelessWidget {
  final String message;
  const _SplashError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Something went wrong:\n$message', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}