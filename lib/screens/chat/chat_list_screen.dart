import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat_preview_tile.dart';
import 'chat_screen.dart';
import 'contact_picker_screen.dart';

/// Body shown for the "Chat" nav item. Lists existing 1:1 conversations;
/// the FAB opens the contact picker to start a new one. Individual
/// threads are pushed as their own route (ChatScreen), not swapped in as
/// a drawer body, since a thread needs a specific "other user" argument.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewsAsync = ref.watch(chatPreviewsProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: previewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load chats: $err')),
        data: (previews) {
          if (previews.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text(
                      'Tap the button below to message a teacher or classmate.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Could not load users: $err')),
            data: (users) {
              final usersById = <String, UserModel>{for (final u in users) u.uid: u};

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: previews.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                itemBuilder: (context, index) {
                  final preview = previews[index];
                  final otherUser = usersById[preview.otherUid];
                  if (otherUser == null) return const SizedBox.shrink();

                  return ChatPreviewTile(
                    otherUser: otherUser,
                    preview: preview,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(otherUser: otherUser)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
        ),
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }
}