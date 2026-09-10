import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/directions_result_model.dart';

/// Thin REST wrapper around the Google Directions API — same
/// zero-new-SDK, dart-define key pattern as GeminiService/NewsApiService.
///
/// This is a *paid* Google Maps Platform API (separate from the Maps
/// SDK powering the map widget itself) and requires:
///   1. Billing enabled on the Google Cloud project.
///   2. "Directions API" enabled for that project.
///   3. A key with NO "Android apps" application restriction — that
///      restriction type only validates native Maps SDK calls, not
///      plain HTTP requests made from Dart. Use "None" or restrict by
///      API only ("Directions API") to keep it scoped.
///
/// Never required for the Bus Tracking feature to work: BusScreen calls
/// [isConfigured] first and falls back to a straight-line estimate if
/// this returns false, or if any request fails.
class DirectionsService {
  static const String _apiKey = String.fromEnvironment('DIRECTIONS_API_KEY');
  static const String _endpoint = 'https://maps.googleapis.com/maps/api/directions/json';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Fetches the driving route from [origin] to [destination]. Returns
  /// null (never throws) on any failure — missing key, network error,
  /// non-OK API status, or an empty route — so callers can silently
  /// fall back to the haversine estimate without extra try/catch noise.
  Future<DirectionsResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (!isConfigured) return null;

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': _apiKey,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;

      final legs = route['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;
      final leg = legs.first as Map<String, dynamic>;

      final distanceMeters = (leg['distance']?['value'] as num?)?.toDouble();
      final durationSeconds = (leg['duration']?['value'] as num?)?.toDouble();
      final overviewPolyline =
          route['overview_polyline']?['points'] as String?;

      if (distanceMeters == null || durationSeconds == null || overviewPolyline == null) {
        return null;
      }

      return DirectionsResult(
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        polylinePoints: _decodePolyline(overviewPolyline),
      );
    } catch (_) {
      // Deliberately swallow every error (timeout, parse failure, no
      // connectivity) — this is a "nice to have" enhancement, never a
      // reason for the bus screen itself to show an error state.
      return null;
    }
  }

  /// Standard Google encoded-polyline decoding algorithm. Pure Dart, no
  /// extra package — same technique used across most Flutter Maps apps.
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}