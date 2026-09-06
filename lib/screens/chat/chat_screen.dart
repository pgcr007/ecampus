import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/role_utils.dart';
import '../../widgets/message_bubble.dart';

/// A single 1:1 conversation. Pushed as its own route from either the
/// chat list or the contact picker — needs [otherUser] to know which
/// thread to load, so it can no longer be a body swapped in by the
/// drawer the way the Phase 6-8 placeholder was.
class ChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _markRead() {
    final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (myUid == null) return;
    ref.read(chatServiceProvider).markThreadAsRead(myUid: myUid, otherUid: widget.otherUser.uid);
  }

  Future<void> _send() async {
    final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    final text = _controller.text;
    if (myUid == null || text.trim().isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();
    try {
      await ref.read(chatServiceProvider).sendMessage(
            senderId: myUid,
            receiverId: widget.otherUser.uid,
            text: text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
    final messagesAsync = ref.watch(conversationProvider(widget.otherUser.uid));

    // Also re-check for newly-arrived unread messages while the thread
    // stays open, not just once at initState (markThreadAsRead is a
    // cheap no-op when nothing is unread).
    ref.listen(conversationProvider(widget.otherUser.uid), (previous, next) {
      next.whenData((_) => _markRead());
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                widget.otherUser.name.isNotEmpty ? widget.otherUser.name[0].toUpperCase() : '?',
                style: TextStyle(color: RoleUtils.badgeColor(widget.otherUser.role), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.otherUser.name, style: const TextStyle(fontSize: 16)),
                  Text(widget.otherUser.role.label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Could not load messages: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Say hello 👋', style: TextStyle(color: AppColors.textSecondary)));
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(message: message, isMine: message.senderId == myUid);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}