// lib/models/tech_news_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore document shape for a published Tech News post — the result
/// of a Teacher/Admin curating an external article and tagging it with
/// a department. See NewsArticle (news_article_model.dart) for the
/// *unpublished*, freshly-fetched-from-the-API shape.
class TechNewsModel {
  final String id;
  final String title;
  final String description;
  final String url;          // link to the original article
  final String imageUrl;     // may be empty — not every article has one
  final String sourceName;   // e.g. "TechCrunch"
  final String department;
  final String postedBy;     // uid of the teacher who published it
  final String postedByName;
  final DateTime? timestamp; // when it was published into the app

  TechNewsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.sourceName,
    required this.department,
    required this.postedBy,
    required this.postedByName,
    required this.timestamp,
  });

  factory TechNewsModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TechNewsModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      url: data['url'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sourceName: data['sourceName'] as String? ?? '',
      department: data['department'] as String? ?? '',
      postedBy: data['postedBy'] as String? ?? '',
      postedByName: data['postedByName'] as String? ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'imageUrl': imageUrl,
      'sourceName': sourceName,
      'department': department,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}