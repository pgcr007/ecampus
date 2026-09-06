import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/bus_location_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/bus_route_data.dart';
import '../../utils/role_utils.dart';
import 'bus_update_screen.dart';

class BusScreen extends ConsumerStatefulWidget {
  const BusScreen({super.key});

  @override
  ConsumerState<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends ConsumerState<BusScreen> {
  GoogleMapController? _mapController;
  BusLocationModel? _lastKnown;

  static const _initialCamera = CameraPosition(
    target: BusRouteData.campusStop,
    zoom: 13,
  );

  /// Haversine distance in km between two lat/lng points — good enough
  /// for a rough "how far is the bus" estimate, no extra package needed.
  double _distanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  String _timeAgo(DateTime? time) {
    if (time == null) return 'never';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busAsync = ref.watch(busLocationStreamProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isTeacher = user != null && RoleUtils.isTeacher(user.role);

    return Scaffold(
      body: busAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load bus location: $err')),
        data: (bus) {
          if (bus != null) _lastKnown = bus;
          final busLatLng =
              _lastKnown != null ? LatLng(_lastKnown!.lat, _lastKnown!.lng) : null;

          // Keep the camera following the bus once we have a position.
          if (busLatLng != null && _mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(busLatLng));
          }

          final distanceKm =
              busLatLng != null ? _distanceKm(busLatLng, BusRouteData.campusStop) : null;
          // Rough demo ETA assuming a 25 km/h average city-road speed.
          final etaMinutes = distanceKm != null ? (distanceKm / 25 * 60).round() : null;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialCamera,
                onMapCreated: (c) => _mapController = c,
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: BusRouteData.routeStops,
                    color: AppColors.primary,
                    width: 4,
                  ),
                },
                markers: {
                  ...BusRouteData.routeStops.asMap().entries.map(
                        (e) => Marker(
                          markerId: MarkerId('stop_${e.key}'),
                          position: e.value,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen),
                          infoWindow: InfoWindow(
                            title: e.key == BusRouteData.routeStops.length - 1
                                ? 'Campus'
                                : 'Stop ${e.key + 1}',
                          ),
                        ),
                      ),
                  if (busLatLng != null)
                    Marker(
                      markerId: const MarkerId('bus'),
                      position: busLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure),
                      infoWindow: InfoWindow(
                        title: _lastKnown?.busName ?? 'College Bus',
                        snippet: 'Updated ${_timeAgo(_lastKnown?.updatedAt)}',
                      ),
                    ),
                },
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: busLatLng == null
                        ? const Text(
                            "No live location yet — the bus hasn't started its trip.",
                            style: TextStyle(color: AppColors.textSecondary),
                          )
                        : Row(
                            children: [
                              const Icon(Icons.directions_bus_rounded, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _lastKnown?.busName ?? 'College Bus',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${distanceKm?.toStringAsFixed(1)} km to campus • '
                                      'ETA ~$etaMinutes min • '
                                      'updated ${_timeAgo(_lastKnown?.updatedAt)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusUpdateScreen()),
              ),
              icon: const Icon(Icons.edit_location_alt_rounded),
              label: const Text('Update Location'),
            )
          : null,
    );
  }
}