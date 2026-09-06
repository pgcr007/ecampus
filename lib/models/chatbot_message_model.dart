enum ChatRole { user, assistant }

/// A single turn in the AI chatbot conversation. Unlike [MessageModel]
/// (Phase 9), this is NOT stored in Firestore — the conversation lives
/// only in the app's memory for this session (see chatbot_provider.dart
/// for the reasoning). Deliberately its own model, not a reuse of
/// MessageModel, since it has no senderId/receiverId/read fields.
class ChatbotMessageModel {
  final String text;
  final ChatRole role;
  final DateTime timestamp;
  final bool isError;

  ChatbotMessageModel({
    required this.text,
    required this.role,
    required this.timestamp,
    this.isError = false,
  });
}