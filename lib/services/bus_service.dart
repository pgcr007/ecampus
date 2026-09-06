import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bus_location_model.dart';

class BusService {
  final _busRef = FirebaseFirestore.instance.collection('bus_locations');

  /// Live stream of a single route's location doc. Emits null if the
  /// route hasn't been set up yet (no doc written for it).
  Stream<BusLocationModel?> streamBusLocation(String routeId) {
    return _busRef.doc(routeId).snapshots().map(
          (doc) => doc.exists ? BusLocationModel.fromDoc(doc) : null,
        );
  }

  /// Writes/updates the bus's current position. Teacher/admin only —
  /// already enforced by your existing Firestore rule:
  /// match /bus_locations/{routeId} { allow write: if isTeacher(); }
  Future<void> updateLocation({
    required String routeId,
    required String busName,
    required double lat,
    required double lng,
  }) async {
    await _busRef.doc(routeId).set({
      'busName': busName,
      'lat': lat,
      'lng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}