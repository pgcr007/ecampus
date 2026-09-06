import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chatbot_message_model.dart';
import '../models/user_model.dart';

/// Thin wrapper around Google's Gemini API (generateContent endpoint).
///
/// Phase 10 revision history:
/// - Switched from OpenAI to Gemini: this is a free academic project and
///   OpenAI's API has no functional free tier (requires funded billing).
///   Gemini's free tier works with just a Google account.
/// - Switched model from gemini-2.0-flash (deprecated/shut down) to
///   gemini-3.6-flash (current GA flash-tier model as of July 2026).
/// - Added thinkingConfig with thinkingLevel: 'low' — Gemini 3.x models
///   have "thinking" on by default, which was eating the maxOutputTokens
///   budget (causing truncated replies) and adding latency (causing
///   timeouts). Low thinking keeps this a fast, simple Q&A chatbot.
/// - Added app-structure grounding + per-role context so answers about
///   "how do I do X in the app" reflect real screens/permissions instead
///   of the model guessing generic steps.
/// - Added markdown stripping since the chat bubble UI renders plain text.
///
/// Key handling: read via --dart-define, never hardcoded, never committed.
class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-3.6-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Grounding for app-specific questions. Keep this in sync with the
  /// actual implemented screens/permissions as phases ship — it is the
  /// only thing standing between "helpful answer" and "confident
  /// hallucination" for questions like "how do I upload a book".
  static const String _appStructure = '''
E-Campus app structure (accurate as of Phase 10):

Roles: Student, Class Representative, Teacher/Admin — chosen at signup via phone OTP.
Signing up as Teacher/Admin requires a college-issued access code at signup; Student
and Class Rep need no code.

Drawer navigation (left menu): Home, Announcements, E-Library, Bus Tracking, Chat,
AI Chatbot, Tech News, Profile. Teacher/Admin additionally sees "Manage Users".

- Announcements: everyone can read all announcements. Only Class Rep and Teacher/Admin
  see a "Post" button (bottom-right) to create a new one. Students cannot post.
- E-Library: everyone can search, filter by semester, download, and read PDFs in-app.
  Only Teacher/Admin sees an "Upload Book" button (bottom-right) to add new books.
  Students and Class Reps cannot upload books — if asked, tell them to request it
  from a teacher/admin instead of describing upload steps.
- Bus Tracking: everyone can view the live bus location on a map. Only Teacher/Admin
  can broadcast/update the live location.
- Chat: real-time one-to-one messaging, available to all roles.
- AI Chatbot: this current screen. General help only — no access to live app data
  (actual books, bus position, messages, announcements). Tell the user to check the
  relevant screen instead of guessing specific content.
- Manage Users and Tech News: not yet built — still placeholder "coming soon" screens.
  If asked about them, say they're planned for a future update, don't invent features.
''';

  static const String _systemPromptBase =
      'You are the AI assistant built into the E-Campus app, used by '
      'students, class representatives, and teachers. Be helpful, clear, '
      'and concise.\n\n'
      'Respond in plain text only — this is a simple chat bubble with no '
      'markdown rendering. Never use **bold**, _italic_, # headers, or '
      '`code fences`. For lists, use plain numbers ("1.", "2.") or hyphens '
      '("- ") on their own lines, with no other symbols.\n\n'
      'Use the app structure reference below as ground truth for any '
      'question about how to do something in the app. Never invent steps, '
      'button names, or permissions that aren\'t in it. If something isn\'t '
      'covered by the reference, say you\'re not sure and suggest checking '
      'the relevant screen, rather than guessing.\n\n$_appStructure';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Sends the running conversation to Gemini and returns the assistant's
  /// reply text. [history] must be in chronological order (oldest first)
  /// and already include the latest user message. [role] is the signed-in
  /// user's role, used to tailor which buttons/actions are mentioned.
  Future<String> sendMessage(
    List<ChatbotMessageModel> history, {
    UserRole? role,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Gemini API key not configured. Run with '
        '--dart-define=GEMINI_API_KEY=AIza... (see handoff doc / README).',
      );
    }

    // Keep only the most recent turns to bound response size/latency.
    final recent =
        history.length > 20 ? history.sublist(history.length - 20) : history;

    // Gemini uses "user" / "model" roles (not "assistant").
    final contents = recent
        .map((m) => {
              'role': m.role == ChatRole.user ? 'user' : 'model',
              'parts': [
                {'text': m.text}
              ],
            })
        .toList();

    final roleLine = role != null
        ? '\nThe person you are currently talking to is signed in as: '
            '${role.label}. Only mention buttons/actions this role actually '
            'has access to, per the reference above.'
        : '';

    final response = await http
        .post(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': _systemPromptBase + roleLine}
              ],
            },
            'contents': contents,
            'generationConfig': {
              'maxOutputTokens': 2048,
              'thinkingConfig': {
                'thinkingLevel': 'low',
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // A prompt can be blocked (e.g. safety filters) with no candidates at all.
    final blockReason = data['promptFeedback']?['blockReason'] as String?;
    if (blockReason != null) {
      throw Exception('Gemini blocked this prompt ($blockReason). Try rephrasing.');
    }

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini API returned no candidates.');
    }

    final finishReason = candidates.first['finishReason'] as String?;
    final parts = candidates.first['content']?['parts'] as List<dynamic>?;
    final text = parts?.map((p) => p['text'] as String? ?? '').join();
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini API returned an empty response.');
    }

    final cleaned = _stripMarkdown(text.trim());
    if (finishReason == 'MAX_TOKENS') {
      return '$cleaned\n\n(cut off — try asking a more specific/shorter question)';
    }
    return cleaned;
  }

  /// Belt-and-suspenders: strips common markdown emphasis/heading markers
  /// in case the model doesn't fully follow the plain-text instruction.
  /// Doesn't touch numbered/hyphen list formatting, which renders fine
  /// as-is in the chat bubble.
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // **bold**
        .replaceAll(RegExp(r'(?<!\*)\*(?!\*)(.*?)\*(?!\*)'), r'$1') // *italic*
        .replaceAll(RegExp(r'__(.*?)__'), r'$1') // __bold__
        .replaceAll(RegExp(r'`{1,3}([^`]*)`{1,3}'), r'$1') // `code`
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), ''); // # headers
  }
}