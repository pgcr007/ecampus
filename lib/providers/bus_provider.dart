import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bus_location_model.dart';
import '../services/bus_service.dart';
import 'auth_provider.dart';

/// Single demo route/document ID — this project ships one college bus.
const String mainRouteId = 'main_route';

final busServiceProvider = Provider<BusService>((ref) => BusService());

final busLocationStreamProvider = StreamProvider<BusLocationModel?>((ref) {
  // Re-subscribe whenever the signed-in user changes, so a stream that
  // errored under a previous account (e.g. before rules were published)
  // doesn't keep getting served after switching to a different test
  // account — same underlying issue as Phase 7's stale-stream gotcha,
  // just triggered by an account switch instead of a rules edit.
  ref.watch(authStateChangesProvider);
  return ref.watch(busServiceProvider).streamBusLocation(mainRouteId);
});