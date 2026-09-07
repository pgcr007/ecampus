// lib/services/news_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article_model.dart';
import '../utils/department_utils.dart';

/// Thin REST wrapper around NewsAPI.org's /v2/everything endpoint —
/// reuses the existing `http` package, same zero-new-SDK pattern as
/// Phase 10's GeminiService.
///
/// Free "Developer" tier: 100 requests/day, no card required, articles
/// delayed ~24h, dev/test use only (not for a shipped commercial app) —
/// an accepted tradeoff for this academic project, same spirit as the
/// Gemini free-tier decision in Phase 10.
///
/// Key handling mirrors Gemini exactly: never hardcoded, read via
/// --dart-define, supplied through the same gitignored env.json.
class NewsApiService {
  static const String _apiKey = String.fromEnvironment('NEWS_API_KEY');
  static const String _endpoint = 'https://newsapi.org/v2/everything';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Fetches recent tech articles relevant to [department]. Throws a
  /// descriptive Exception on any failure path (missing key, HTTP
  /// error, empty results) — the calling screen shows this directly,
  /// same graceful-degradation approach as GeminiService.
  Future<List<NewsArticle>> fetchTechNews({required String department}) async {
    if (!isConfigured) {
      throw Exception(
        'News API key not configured. Run with '
        '--dart-define=NEWS_API_KEY=... (see handoff doc / README).',
      );
    }

    final query = DepartmentUtils.newsQueryFor(department);
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'q': query,
      'language': 'en',
      'sortBy': 'publishedAt',
      'pageSize': '20',
      'apiKey': _apiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message'] as String? ?? response.body;
      throw Exception('News API error (${response.statusCode}): $message');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final articlesJson = data['articles'] as List<dynamic>?;
    if (articlesJson == null || articlesJson.isEmpty) {
      throw Exception('No articles found for "$department" right now — try again shortly.');
    }

    return articlesJson
        .map((a) => NewsArticle.fromJson(a as Map<String, dynamic>))
        // Some sources return entries with "[Removed]" as a placeholder
        // when the original article was taken down — filter those out.
        .where((a) => a.title != '[Removed]' && a.url.isNotEmpty)
        .toList();
  }
}