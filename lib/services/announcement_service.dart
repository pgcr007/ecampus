import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final _announcements = FirebaseFirestore.instance.collection('announcements');

  Stream<List<AnnouncementModel>> announcementsStream() {
    return _announcements
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AnnouncementModel.fromDoc).toList());
  }

  Future<void> postAnnouncement(AnnouncementModel announcement) {
    return _announcements.add(announcement.toMap());
  }
}