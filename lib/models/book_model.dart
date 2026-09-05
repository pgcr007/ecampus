import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the `books` collection schema in docs/Firestore_Schema_ECampus.md
class BookModel {
  final String bookId;
  final String title;
  final String subject;
  final int semester;
  final String fileUrl;
  final String uploadedBy;
  final DateTime? uploadedAt;

  BookModel({
    required this.bookId,
    required this.title,
    required this.subject,
    required this.semester,
    required this.fileUrl,
    required this.uploadedBy,
    this.uploadedAt,
  });

  factory BookModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BookModel(
      bookId: doc.id,
      title: data['title'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      semester: (data['semester'] as num?)?.toInt() ?? 0,
      fileUrl: data['fileUrl'] as String? ?? '',
      uploadedBy: data['uploadedBy'] as String? ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }
}