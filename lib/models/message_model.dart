import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat message. Stored as a **flat document** in the top-level
/// `chats` collection (not nested sub-collections) — this matches the
/// Firestore rules structure that was already published back in Phase
/// 4/5: each message doc carries its own `senderId` / `receiverId`, and
/// a "conversation" between two users is just every message where those
/// two UIDs appear in either order.
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime? timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.read,
  });

  factory MessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      read: data['read'] as bool? ?? false,
    );
  }
}