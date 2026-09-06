import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// Firestore logic for the flat `chats` collection. Every document is
/// one message; a "conversation" is derived at query-time rather than
/// stored as its own thread document (see message_model.dart for why).
class ChatService {
  final _chats = FirebaseFirestore.instance.collection('chats');

  /// Every message that involves [myUid], newest first. Used to build
  /// the chat list screen — one preview per distinct other-user is
  /// derived client-side from this stream (see chat_provider.dart).
  Stream<List<MessageModel>> allMessagesForUser(String myUid) {
    return _chats
        .where(
          Filter.or(
            Filter('senderId', isEqualTo: myUid),
            Filter('receiverId', isEqualTo: myUid),
          ),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  /// The full thread between two specific users, oldest first (natural
  /// reading order for a chat screen).
  Stream<List<MessageModel>> conversation(String myUid, String otherUid) {
    return _chats
        .where(
          Filter.or(
            Filter.and(
              Filter('senderId', isEqualTo: myUid),
              Filter('receiverId', isEqualTo: otherUid),
            ),
            Filter.and(
              Filter('senderId', isEqualTo: otherUid),
              Filter('receiverId', isEqualTo: myUid),
            ),
          ),
        )
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    return _chats.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Marks every message *sent to me* by [otherUid] as read. Called when
  /// ChatScreen opens a thread. Requires the Phase 9 rules fix above —
  /// the original Phase 4/5 rule only let the sender update a message.
  Future<void> markThreadAsRead({
    required String myUid,
    required String otherUid,
  }) async {
    final unread = await _chats
        .where('senderId', isEqualTo: otherUid)
        .where('receiverId', isEqualTo: myUid)
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}