import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String postedBy;     // uid of the classrep/teacher who posted
  final String postedByName;
  final DateTime? timestamp;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.postedBy,
    required this.postedByName,
    required this.timestamp,
  });

  factory AnnouncementModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      postedBy: data['postedBy'] as String? ?? '',
      postedByName: data['postedByName'] as String? ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}