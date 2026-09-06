import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import 'auth_provider.dart';

final announcementServiceProvider =
    Provider<AnnouncementService>((ref) => AnnouncementService());

/// Watches auth state so this stream re-subscribes cleanly on every
/// account switch — same fix as allUsersProvider and Phase 8's
/// busLocationStreamProvider.
final announcementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) {
    return Stream.value(<AnnouncementModel>[]);
  }
  return ref.watch(announcementServiceProvider).announcementsStream();
});