// lib/widgets/tech_news_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tech_news_model.dart';
import '../theme/app_colors.dart';
import '../utils/time_utils.dart';

class TechNewsCard extends StatelessWidget {
  final TechNewsModel news;

  const TechNewsCard({super.key, required this.news});

  Future<void> _openArticle(BuildContext context) async {
    if (news.url.isEmpty) return;
    final uri = Uri.parse(news.url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the article link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _openArticle(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  news.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported_rounded, color: AppColors.textSecondary),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          news.department,
                          style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(news.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  if (news.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      news.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '${news.sourceName} · via ${news.postedByName} · ${TimeUtils.fullTimestamp(news.timestamp)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}