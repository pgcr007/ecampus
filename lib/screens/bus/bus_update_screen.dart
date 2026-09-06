import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/bus_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/bus_route_data.dart';

class BusUpdateScreen extends ConsumerStatefulWidget {
  const BusUpdateScreen({super.key});

  @override
  ConsumerState<BusUpdateScreen> createState() => _BusUpdateScreenState();
}

class _BusUpdateScreenState extends ConsumerState<BusUpdateScreen> {
  GoogleMapController? _mapController;
  Timer? _simTimer;
  LatLng? _currentMarker;
  bool _isSimulating = false;

  // Which leg of the route we're on, and how far along it (0.0 -> 1.0).
  int _legIndex = 0;
  double _legProgress = 0.0;

  static const _stepsPerLeg = 20; // ticks needed to cross one leg
  static const _tickInterval = Duration(seconds: 2);

  @override
  void dispose() {
    _simTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _publish(LatLng point) async {
    setState(() => _currentMarker = point);
    await ref.read(busServiceProvider).updateLocation(
          routeId: mainRouteId,
          busName: BusRouteData.busName,
          lat: point.latitude,
          lng: point.longitude,
        );
  }

  void _onMapTapped(LatLng point) {
    if (_isSimulating) return; // ignore manual taps mid-simulation
    _publish(point);
  }

  LatLng _lerp(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  void _startSimulation() {
    final stops = BusRouteData.routeStops;
    if (stops.length < 2) return;

    setState(() => _isSimulating = true);
    _simTimer = Timer.periodic(_tickInterval, (_) {
      final from = stops[_legIndex];
      final to = stops[(_legIndex + 1) % stops.length];
      final point = _lerp(from, to, _legProgress);

      _publish(point);
      _mapController?.animateCamera(CameraUpdate.newLatLng(point));

      _legProgress += 1 / _stepsPerLeg;
      if (_legProgress >= 1.0) {
        _legProgress = 0.0;
        _legIndex = (_legIndex + 1) % stops.length;
      }
    });
  }

  void _stopSimulation() {
    _simTimer?.cancel();
    setState(() => _isSimulating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Bus Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary.withOpacity(0.06),
            padding: const EdgeInsets.all(12),
            child: Text(
              _isSimulating
                  ? 'Auto-drive running — the bus is moving itself along the route.'
                  : "Tap anywhere on the map to publish the bus's current position, or start auto-drive for a hands-free demo.",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: BusRouteData.routeStops.first,
                zoom: 13,
              ),
              onMapCreated: (c) => _mapController = c,
              onTap: _onMapTapped,
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: BusRouteData.routeStops,
                  color: AppColors.primary,
                  width: 4,
                ),
              },
              markers: {
                if (_currentMarker != null)
                  Marker(
                    markerId: const MarkerId('bus'),
                    position: _currentMarker!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSimulating ? _stopSimulation : _startSimulation,
                icon: Icon(_isSimulating ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(_isSimulating ? 'Stop Auto Drive' : 'Start Auto Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSimulating ? Colors.redAccent : AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}