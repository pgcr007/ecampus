import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// NEW
/// Watches auth state so this stream properly re-subscribes on every
/// account switch, instead of potentially serving an already-errored
/// stream to a newly signed-in user — same fix as busLocationStreamProvider
/// in Phase 8.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) {
    return Stream.value(<UserModel>[]);
  }

  return FirebaseFirestore.instance.collection('users').snapshots().map(
        (snap) => snap.docs.map(UserModel.fromDoc).toList(),
      );
});

/// One row per conversation the current user is part of: the other
/// user's uid, their latest message, and how many of their messages to
/// me are still unread. Derived client-side from the flat message stream.
class ChatPreview {
  final String otherUid;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool lastMessageIsMine;

  ChatPreview({
    required this.otherUid,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.lastMessageIsMine,
  });
}

final chatPreviewsProvider = StreamProvider<List<ChatPreview>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final myUid = authState.valueOrNull?.uid;
  if (myUid == null) return Stream.value(<ChatPreview>[]);

  final chatService = ref.watch(chatServiceProvider);
  return chatService.allMessagesForUser(myUid).map((messages) {
    final byOtherUid = <String, List<MessageModel>>{};
    for (final m in messages) {
      final other = m.senderId == myUid ? m.receiverId : m.senderId;
      byOtherUid.putIfAbsent(other, () => []).add(m);
    }

    final previews = byOtherUid.entries.map((entry) {
      final msgs = entry.value; // already newest-first from the stream
      final latest = msgs.first;
      final unread = msgs.where((m) => m.receiverId == myUid && !m.read).length;
      return ChatPreview(
        otherUid: entry.key,
        lastMessage: latest.text,
        lastMessageTime: latest.timestamp,
        unreadCount: unread,
        lastMessageIsMine: latest.senderId == myUid,
      );
    }).toList();

    previews.sort((a, b) {
      final at = a.lastMessageTime;
      final bt = b.lastMessageTime;
      if (at == null || bt == null) return 0;
      return bt.compareTo(at);
    });
    return previews;
  });
});

/// The message thread with one specific other user.
final conversationProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, otherUid) {
  final authState = ref.watch(authStateChangesProvider);
  final myUid = authState.valueOrNull?.uid;
  if (myUid == null) return Stream.value(<MessageModel>[]);
  return ref.watch(chatServiceProvider).conversation(myUid, otherUid);
});