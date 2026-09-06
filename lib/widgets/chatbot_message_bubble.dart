import 'package:flutter/material.dart';
import '../models/chatbot_message_model.dart';
import '../theme/app_colors.dart';
import '../utils/time_utils.dart';

class ChatbotMessageBubble extends StatelessWidget {
  final ChatbotMessageModel message;

  const ChatbotMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final bubbleColor = message.isError
        ? const Color(0xFFFDECEA)
        : (isUser ? AppColors.primary : Colors.white);
    final textColor = message.isError
        ? const Color(0xFFB3261E)
        : (isUser ? Colors.white : AppColors.textPrimary);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.secondary,
              child: Icon(
                message.isError ? Icons.error_outline_rounded : Icons.smart_toy_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 14),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.text, style: TextStyle(color: textColor, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    TimeUtils.chatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : AppColors.textSecondary,
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