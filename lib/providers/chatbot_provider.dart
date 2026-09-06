import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chatbot_message_model.dart';
import '../models/user_model.dart';
import '../services/gemini_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

class ChatbotState {
  final List<ChatbotMessageModel> messages;
  final bool sending;

  const ChatbotState({this.messages = const [], this.sending = false});

  ChatbotState copyWith({List<ChatbotMessageModel>? messages, bool? sending}) {
    return ChatbotState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final GeminiService _service;

  ChatbotNotifier(this._service) : super(const ChatbotState());

  Future<void> sendMessage(String text, {UserRole? role}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    final userMessage = ChatbotMessageModel(
      text: trimmed,
      role: ChatRole.user,
      timestamp: DateTime.now(),
    );

    final withUserMessage = [...state.messages, userMessage];
    state = state.copyWith(messages: withUserMessage, sending: true);

    try {
      final reply = await _service.sendMessage(withUserMessage, role: role);
      final assistantMessage = ChatbotMessageModel(
        text: reply,
        role: ChatRole.assistant,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        sending: false,
      );
    } catch (e) {
      final errorMessage = ChatbotMessageModel(
        text: 'Sorry, something went wrong: $e',
        role: ChatRole.assistant,
        timestamp: DateTime.now(),
        isError: true,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        sending: false,
      );
    }
  }

  void clear() {
    state = const ChatbotState();
  }
}

final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier(ref.watch(geminiServiceProvider));
});