import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chatbot_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chatbot_message_bubble.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'How do I upload a book to the library?',
    'Explain how bus tracking works',
    'Give me a quick study tip for exams',
  ];

    void _send([String? text]) {
    final value = text ?? _controller.text;
    if (value.trim().isEmpty) return;
    _controller.clear();
    final role = ref.read(userProfileProvider).valueOrNull?.role;
    ref.read(chatbotProvider.notifier).sendMessage(value, role: role);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text(
          'This only clears the chat on this screen — nothing was ever stored on a server.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(chatbotProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatbotState = ref.watch(chatbotProvider);
    final messages = chatbotState.messages;
    final sending = chatbotState.sending;

    ref.listen(chatbotProvider, (previous, next) {
      final lengthChanged = previous?.messages.length != next.messages.length;
      final sendingChanged = previous?.sending != next.sending;
      if (lengthChanged || sendingChanged) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI Assistant',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                if (messages.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
                    tooltip: 'Clear conversation',
                    onPressed: _confirmClear,
                  ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _EmptyState(onSuggestionTap: _send, suggestions: _suggestions)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const _TypingBubble();
                      }
                      return ChatbotMessageBubble(message: messages[index]);
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
                        hintText: 'Ask the AI assistant…',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: sending ? null : () => _send(),
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

class _EmptyState extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  const _EmptyState({required this.suggestions, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Ask me anything',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Study help, general questions, or how to use E-Campus.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map((s) => ActionChip(
                        label: Text(s),
                        backgroundColor: Colors.white,
                        onPressed: () => onSuggestionTap(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 6),
        child: _TypingRow(),
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: const SizedBox(width: 32, height: 10, child: _TypingDots()),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.2) % 1.0;
            final scale = t < 0.5 ? 0.6 + t : 1.1 - t;
            return Opacity(
              opacity: 0.4 + 0.6 * scale.clamp(0.0, 1.0),
              child: Container(
                width: 6,
                height: 6,
                decoration:
                    const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
              ),
            );
          }),
        );
      },
    );
  }
}