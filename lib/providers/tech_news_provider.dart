// lib/providers/tech_news_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tech_news_model.dart';
import '../services/news_api_service.dart';
import '../services/tech_news_service.dart';
import 'auth_provider.dart';

final techNewsServiceProvider = Provider<TechNewsService>((ref) => TechNewsService());
final newsApiServiceProvider = Provider<NewsApiService>((ref) => NewsApiService());

/// Watches auth state so this stream re-subscribes cleanly on account
/// switch — the same standing project rule every Firestore StreamProvider
/// has followed since Phase 8 (busLocationStreamProvider).
///
/// Keyed by department string ('' or any non-empty value the screen
/// passes in) so switching the feed's department filter just re-reads
/// this family with a new argument instead of needing separate providers.
final techNewsStreamProvider =
    StreamProvider.family<List<TechNewsModel>, String>((ref, department) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) {
    return Stream.value(<TechNewsModel>[]);
  }
  return ref.watch(techNewsServiceProvider).techNewsStream(department: department);
});