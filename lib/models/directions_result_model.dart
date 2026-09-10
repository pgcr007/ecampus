import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Parsed result of a single Google Directions API request between two
/// points — real road distance/duration plus the road-snapped polyline,
/// as opposed to the straight-line haversine estimate used as a fallback
/// in [BusService]/[BusScreen] when this isn't available.
class DirectionsResult {
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> polylinePoints;

  const DirectionsResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylinePoints,
  });

  double get distanceKm => distanceMeters / 1000;
  int get durationMinutes => (durationSeconds / 60).round();
}