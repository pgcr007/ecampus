import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/bus_location_model.dart';
import '../../models/directions_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/bus_route_data.dart';
import '../../utils/role_utils.dart';
import 'bus_update_screen.dart';

/// Muted, low-clutter map style so the route/markers — not Google's
/// default POI icons and labels — are the visual focus. Applied via
/// GoogleMapController.setMapStyle for compatibility across
/// google_maps_flutter versions.
const String _kMapStyle = '''
[
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#e7ebf1"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#eef1f6"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dbe3f0"}]},
  {"featureType": "road", "elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"featureType": "landscape", "elementType": "geometry", "stylers": [{"color": "#f5f7fa"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#cfe3ff"}]},
  {"featureType": "administrative", "elementType": "labels.text.fill", "stylers": [{"color": "#6b7280"}]}
]
''';

class BusScreen extends ConsumerStatefulWidget {
  const BusScreen({super.key});

  @override
  ConsumerState<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends ConsumerState<BusScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  BusLocationModel? _lastKnown;
  bool _hasCenteredOnce = false;

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _campusIcon;

  late final AnimationController _pulseController;

  // --- Live road-route (Directions API) state -----------------------
  // Optional enhancement: real road distance/ETA/polyline instead of
  // the haversine straight-line estimate. Throttled so a busy Firestore
  // stream doesn't fire a paid API call on every single update.
  DirectionsResult? _liveDirections;
  LatLng? _lastDirectionsOrigin;
  DateTime? _lastDirectionsFetchAt;
  bool _directionsInFlight = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadCustomIcons();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Custom marker bitmaps — drawn once with dart:ui so the bus, stops and
  // campus each get a distinct, on-brand pin instead of Google's default
  // teardrops. No extra packages needed.
  // ---------------------------------------------------------------------
  Future<BitmapDescriptor> _buildMarkerBitmap({
    IconData? iconData,
    required Color background,
    double size = 130,
    double iconSizeFactor = 0.52,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(center.translate(0, 4), radius - 8, shadowPaint);

    canvas.drawCircle(center, radius - 5, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius - 11, Paint()..color = background);

    if (iconData != null) {
      final tp = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: size * iconSizeFactor,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Colors.white,
          ),
        )
        ..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    // ignore: deprecated_member_use
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _loadCustomIcons() async {
    final results = await Future.wait([
      _buildMarkerBitmap(
        iconData: Icons.directions_bus_rounded,
        background: AppColors.primary,
        size: 150,
        iconSizeFactor: 0.5,
      ),
      _buildMarkerBitmap(
        iconData: Icons.circle,
        background: AppColors.secondary,
        size: 70,
        iconSizeFactor: 0.001, // effectively a plain dot
      ),
      _buildMarkerBitmap(
        iconData: Icons.flag_rounded,
        background: AppColors.teacherBadge,
        size: 140,
        iconSizeFactor: 0.48,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _busIcon = results[0];
      _stopIcon = results[1];
      _campusIcon = results[2];
    });
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

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

  /// Index of the route stop nearest the bus's current position — used
  /// as a rough "how far along the route" progress indicator.
  int _nearestStopIndex(LatLng busPos) {
    var bestIndex = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < BusRouteData.routeStops.length; i++) {
      final d = _distanceKm(busPos, BusRouteData.routeStops[i]);
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  void _recenter(LatLng target) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15.5));
  }

  Future<void> _fitRouteBounds() async {
    if (_mapController == null) return;
    final points = BusRouteData.routeStops;
    if (points.isEmpty) return;
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  /// Fetches a real road route/ETA from the bus's current position to
  /// campus — but only if the bus has moved a meaningful distance
  /// (>50 m) or enough time has passed (>45 s) since the last call, and
  /// only if DIRECTIONS_API_KEY is actually configured. Fails silently:
  /// on any error, `_liveDirections` just keeps its last good value (or
  /// null), and the UI falls back to the haversine estimate.
  void _maybeFetchLiveDirections(LatLng busPos) {
    final directions = ref.read(directionsServiceProvider);
    if (!directions.isConfigured || _directionsInFlight) return;

    final now = DateTime.now();
    final movedFar = _lastDirectionsOrigin == null ||
        _distanceKm(_lastDirectionsOrigin!, busPos) > 0.05;
    final isStale = _lastDirectionsFetchAt == null ||
        now.difference(_lastDirectionsFetchAt!) > const Duration(seconds: 45);
    if (!movedFar && !isStale) return;

    _lastDirectionsOrigin = busPos;
    _lastDirectionsFetchAt = now;
    _directionsInFlight = true;

    directions
        .getRoute(origin: busPos, destination: BusRouteData.campusStop)
        .then((result) {
      if (!mounted) return;
      setState(() {
        _directionsInFlight = false;
        if (result != null) _liveDirections = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final busAsync = ref.watch(busLocationStreamProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isTeacher = user != null && RoleUtils.isTeacher(user.role);

    return Scaffold(
      body: busAsync.when(
        loading: () => const _BusLoadingState(),
        error: (err, _) => _BusErrorState(error: err.toString()),
        data: (bus) {
          if (bus != null) _lastKnown = bus;
          final busLatLng =
              _lastKnown != null ? LatLng(_lastKnown!.lat, _lastKnown!.lng) : null;

          if (busLatLng != null && _mapController != null && !_hasCenteredOnce) {
            _hasCenteredOnce = true;
            _recenter(busLatLng);
          }
          if (busLatLng != null) _maybeFetchLiveDirections(busLatLng);

          // Straight-line haversine fallback — always available, no API key needed.
          final estimatedDistanceKm =
              busLatLng != null ? _distanceKm(busLatLng, BusRouteData.campusStop) : null;
          // Rough demo ETA assuming a 25 km/h average city-road speed.
          final estimatedEtaMinutes =
              estimatedDistanceKm != null ? (estimatedDistanceKm / 25 * 60).round() : null;

          // Prefer the real Directions API result when we have one for
          // roughly the bus's current position; otherwise fall back.
          final hasFreshLiveRoute = _liveDirections != null &&
              busLatLng != null &&
              _lastDirectionsOrigin != null &&
              _distanceKm(_lastDirectionsOrigin!, busLatLng) < 0.3;
          final distanceKm =
              hasFreshLiveRoute ? _liveDirections!.distanceKm : estimatedDistanceKm;
          final etaMinutes =
              hasFreshLiveRoute ? _liveDirections!.durationMinutes : estimatedEtaMinutes;

          final isLive = _lastKnown?.updatedAt != null &&
              DateTime.now().difference(_lastKnown!.updatedAt!).inMinutes < 5;
          final stopIndex = busLatLng != null ? _nearestStopIndex(busLatLng) : null;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: BusRouteData.campusStop,
                  zoom: 13,
                ),
                onMapCreated: (c) {
                  _mapController = c;
                  c.setMapStyle(_kMapStyle);
                  if (busLatLng == null) _fitRouteBounds();
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                polylines: {
                  // Soft wide outline underneath for a "road" feel.
                  Polyline(
                    polylineId: const PolylineId('route_outline'),
                    points: BusRouteData.routeStops,
                    color: Colors.white,
                    width: 7,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                  ),
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: BusRouteData.routeStops,
                    color: AppColors.primary,
                    width: 4,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                    patterns: const [],
                  ),
                  // Real road-snapped route from the bus's current spot
                  // to campus — only drawn once a live Directions result
                  // is available, dashed so it reads as "current path"
                  // distinct from the fixed blue campus-route line.
                  if (hasFreshLiveRoute)
                    Polyline(
                      polylineId: const PolylineId('live_route'),
                      points: _liveDirections!.polylinePoints,
                      color: AppColors.secondary,
                      width: 5,
                      patterns: [PatternItem.dash(24), PatternItem.gap(12)],
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      zIndex: 1,
                    ),
                },
                markers: {
                  ...BusRouteData.routeStops.asMap().entries.map((e) {
                    final isCampus = e.key == BusRouteData.routeStops.length - 1;
                    return Marker(
                      markerId: MarkerId('stop_${e.key}'),
                      position: e.value,
                      anchor: const Offset(0.5, 0.5),
                      icon: isCampus
                          ? (_campusIcon ??
                              BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange))
                          : (_stopIcon ??
                              BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen)),
                      infoWindow: InfoWindow(
                        title: isCampus ? 'Campus' : 'Stop ${e.key + 1}',
                        snippet: isCampus ? 'Final destination' : null,
                      ),
                    );
                  }),
                  if (busLatLng != null)
                    Marker(
                      markerId: const MarkerId('bus'),
                      position: busLatLng,
                      anchor: const Offset(0.5, 0.5),
                      zIndex: 2,
                      icon: _busIcon ??
                          BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueAzure),
                      infoWindow: InfoWindow(
                        title: _lastKnown?.busName ?? 'College Bus',
                        snippet: 'Updated ${_timeAgo(_lastKnown?.updatedAt)}',
                      ),
                    ),
                },
              ),

              // Top-left status pill.
              Positioned(
                top: 12,
                left: 12,
                child: _LiveStatusChip(isLive: isLive, pulse: _pulseController),
              ),

              // Top-right stop-count pill.
              Positioned(
                top: 12,
                right: 12,
                child: _InfoPill(
                  icon: Icons.alt_route_rounded,
                  label: '${BusRouteData.routeStops.length} stops',
                ),
              ),

              // Recenter + (teacher) update-location buttons, stacked
              // above the info panel.
              Positioned(
                right: 12,
                bottom: 210,
                child: Column(
                  children: [
                    if (isTeacher)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RoundActionButton(
                          icon: Icons.edit_location_alt_rounded,
                          backgroundColor: AppColors.primary,
                          iconColor: Colors.white,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BusUpdateScreen()),
                          ),
                        ),
                      ),
                    _RoundActionButton(
                      icon: Icons.my_location_rounded,
                      backgroundColor: Colors.white,
                      iconColor: AppColors.primary,
                      onTap: () {
                        if (busLatLng != null) {
                          _recenter(busLatLng);
                        } else {
                          _fitRouteBounds();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Bottom info panel.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BusInfoPanel(
                  bus: _lastKnown,
                  isLive: isLive,
                  distanceKm: distanceKm,
                  etaMinutes: etaMinutes,
                  usingLiveRoute: hasFreshLiveRoute,
                  stopIndex: stopIndex,
                  totalStops: BusRouteData.routeStops.length,
                  timeAgoText: _timeAgo(_lastKnown?.updatedAt),
                  pulse: _pulseController,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Presentational widgets
// ===========================================================================

class _LiveStatusChip extends StatelessWidget {
  final bool isLive;
  final AnimationController pulse;
  const _LiveStatusChip({required this.isLive, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? AppColors.secondary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final scale = isLive ? 0.8 + (pulse.value * 0.5) : 1.0;
              final opacity = isLive ? 1.0 - (pulse.value * 0.5) : 1.0;
              return SizedBox(
                width: 14,
                height: 14,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isLive)
                      Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale + 0.8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            isLive ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  const _RoundActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _BusInfoPanel extends StatelessWidget {
  final BusLocationModel? bus;
  final bool isLive;
  final double? distanceKm;
  final int? etaMinutes;
  final bool usingLiveRoute;
  final int? stopIndex;
  final int totalStops;
  final String timeAgoText;
  final AnimationController pulse;

  const _BusInfoPanel({
    required this.bus,
    required this.isLive,
    required this.distanceKm,
    required this.etaMinutes,
    required this.usingLiveRoute,
    required this.stopIndex,
    required this.totalStops,
    required this.timeAgoText,
    required this.pulse,
  });

  String get _statusText {
    if (bus == null) return "Bus hasn't started its trip yet";
    if (isLive) return 'On the way to campus';
    return 'Last seen a while ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag-handle affordance.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, Color(0xFF1B4FD6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      if (isLive)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: AnimatedBuilder(
                            animation: pulse,
                            builder: (context, _) => Opacity(
                              opacity: 0.6 + (pulse.value * 0.4),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus?.busName ?? BusRouteData.busName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _statusText,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (bus != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (usingLiveRoute
                                          ? AppColors.secondary
                                          : AppColors.textSecondary)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  usingLiveRoute ? 'LIVE ROUTE' : 'ESTIMATED',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: usingLiveRoute
                                        ? AppColors.secondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (etaMinutes != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '~$etaMinutes',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'min ETA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.social_distance_rounded,
                      label: 'Distance',
                      value: distanceKm != null
                          ? '${distanceKm!.toStringAsFixed(1)} km'
                          : '—',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.update_rounded,
                      label: 'Updated',
                      value: bus != null ? timeAgoText : '—',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.pin_drop_rounded,
                      label: 'Nearest stop',
                      value: stopIndex != null
                          ? (stopIndex == totalStops - 1
                              ? 'Campus'
                              : 'Stop ${stopIndex! + 1}')
                          : '—',
                    ),
                  ),
                ],
              ),
              if (stopIndex != null) ...[
                const SizedBox(height: 16),
                _RouteProgress(totalStops: totalStops, currentIndex: stopIndex!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A small stepper showing how far along the route the bus has travelled,
/// ending in a flag marker for campus — mirrors the map markers so the
/// panel and the map read as one connected story.
class _RouteProgress extends StatelessWidget {
  final int totalStops;
  final int currentIndex;
  const _RouteProgress({required this.totalStops, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalStops * 2 - 1, (i) {
        if (i.isOdd) {
          final segmentIndex = i ~/ 2;
          final passed = segmentIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: passed ? AppColors.secondary : AppColors.background,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final stopIdx = i ~/ 2;
        final isCampus = stopIdx == totalStops - 1;
        final reached = stopIdx <= currentIndex;
        return Column(
          children: [
            Container(
              width: isCampus ? 22 : 14,
              height: isCampus ? 22 : 14,
              decoration: BoxDecoration(
                color: reached
                    ? (isCampus ? AppColors.teacherBadge : AppColors.secondary)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: reached
                      ? (isCampus ? AppColors.teacherBadge : AppColors.secondary)
                      : AppColors.textSecondary.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isCampus
                  ? Icon(
                      Icons.flag_rounded,
                      size: 12,
                      color: reached ? Colors.white : AppColors.textSecondary,
                    )
                  : (reached
                      ? const Icon(Icons.check, size: 9, color: Colors.white)
                      : null),
            ),
          ],
        );
      }),
    );
  }
}

class _BusLoadingState extends StatelessWidget {
  const _BusLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Locating the bus…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusErrorState extends StatelessWidget {
  final String error;
  const _BusErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Could not load the bus location',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}