import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a single document in the `bus_locations` collection.
/// One doc per bus/route — this project ships one demo route
/// (see `mainRouteId` in bus_provider.dart), but the model and
/// service support more route IDs later without changes here.
class BusLocationModel {
  final String routeId;
  final String busName;
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  BusLocationModel({
    required this.routeId,
    required this.busName,
    required this.lat,
    required this.lng,
    this.updatedAt,
  });

  factory BusLocationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BusLocationModel(
      routeId: doc.id,
      busName: data['busName'] as String? ?? 'College Bus',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}