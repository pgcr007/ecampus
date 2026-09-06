import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../utils/role_utils.dart';
import '../utils/time_utils.dart';

class ChatPreviewTile extends StatelessWidget {
  final UserModel otherUser;
  final ChatPreview preview;
  final VoidCallback onTap;

  const ChatPreviewTile({
    super.key,
    required this.otherUser,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = preview.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: RoleUtils.badgeColor(otherUser.role).withOpacity(0.15),
        child: Text(
          otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : '?',
          style: TextStyle(color: RoleUtils.badgeColor(otherUser.role), fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        preview.lastMessageIsMine ? 'You: ${preview.lastMessage}' : preview.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            TimeUtils.chatTimestamp(preview.lastMessageTime),
            style: TextStyle(fontSize: 12, color: hasUnread ? AppColors.primary : AppColors.textSecondary),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 9,
              backgroundColor: AppColors.primary,
              child: Text('${preview.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }
}