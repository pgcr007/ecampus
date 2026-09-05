import 'package:flutter/material.dart';

import '../models/book_model.dart';
import '../theme/app_colors.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final double? downloadProgress; // null = not currently downloading
  final bool isDownloaded;
  final VoidCallback onRead;
  final VoidCallback onDownload;
  final VoidCallback onOpenDownloaded;

  const BookCard({
    super.key,
    required this.book,
    required this.downloadProgress,
    required this.isDownloaded,
    required this.onRead,
    required this.onDownload,
    required this.onOpenDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${book.subject} • Semester ${book.semester}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  if (downloadProgress != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: downloadProgress,
                          backgroundColor: Colors.grey.shade200,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(downloadProgress! * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: onRead,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: const Text('Read'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isDownloaded)
                          TextButton.icon(
                            onPressed: onOpenDownloaded,
                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                            label: const Text('Downloaded'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: onDownload,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Download'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
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