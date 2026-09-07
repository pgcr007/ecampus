// lib/services/tech_news_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tech_news_model.dart';

class TechNewsService {
  final _techNews = FirebaseFirestore.instance.collection('tech_news');

  /// If [department] is null/empty, returns everything (used when a
  /// user hasn't set a department yet, or explicitly wants "All").
  /// Otherwise filters by department — this is the query that needs
  /// the department(Asc) + timestamp(Desc) composite index.
  Stream<List<TechNewsModel>> techNewsStream({String? department}) {
    Query<Map<String, dynamic>> query =
        _techNews.orderBy('timestamp', descending: true);
    if (department != null && department.isNotEmpty) {
      query = _techNews
          .where('department', isEqualTo: department)
          .orderBy('timestamp', descending: true);
    }
    return query.snapshots().map((snap) => snap.docs.map(TechNewsModel.fromDoc).toList());
  }

  Future<void> publish(TechNewsModel news) {
    return _techNews.add(news.toMap());
  }
}