import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Placeholder demo route. Replace these with your actual bus route —
/// right-click any point on Google Maps and "copy coordinates" to get
/// real lat/lng pairs for your college's pickup stops.
class BusRouteData {
  BusRouteData._();

  /// Ordered stops the simulated bus drives through, looping back to
  /// the first stop after reaching the last one.
  static const List<LatLng> routeStops = [
    LatLng(19.2403, 73.1305), // Stop 1 — demo
    LatLng(19.2183, 73.1436), // Stop 2 — demo
    LatLng(19.2065, 73.1699), // Stop 3 — demo
    LatLng(19.1926, 73.1801), // Stop 4 — Campus (demo)
  ];

  static const LatLng campusStop = LatLng(19.1926, 73.1801); // same as last stop above

  static const String busName = 'College Bus 1';
}