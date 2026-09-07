// lib/models/news_article_model.dart


class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String sourceName;
  final DateTime? publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String? ?? '(untitled)',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['urlToImage'] as String? ?? '',
      sourceName: (json['source'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown source',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    );
  }
}