import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/role_utils.dart';
import '../../widgets/book_card.dart';
import 'book_upload_screen.dart';
import 'pdf_viewer_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedSemester; // null = All

  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadedPaths = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkDownloaded(List<BookModel> books) async {
    final service = ref.read(libraryServiceProvider);
    for (final book in books) {
      if (_downloadedPaths.containsKey(book.bookId)) continue;
      final path = await service.getLocalPathIfExists(book.bookId);
      if (path != null && mounted) {
        setState(() => _downloadedPaths[book.bookId] = path);
      }
    }
  }

  Future<void> _download(BookModel book) async {
    setState(() => _downloadProgress[book.bookId] = 0);
    try {
      final path = await ref.read(libraryServiceProvider).downloadBook(
        book,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress[book.bookId] = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloadProgress.remove(book.bookId);
        _downloadedPaths[book.bookId] = path;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${book.title} downloaded')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloadProgress.remove(book.bookId));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  void _openReader(BookModel book, {bool useLocal = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: book.title,
          networkUrl: useLocal ? null : book.fileUrl,
          localPath: useLocal ? _downloadedPaths[book.bookId] : null,
        ),
      ),
    );
  }

  Widget _semesterChip(int? semester, String label) {
    final selected = _selectedSemester == semester;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedSemester = semester),
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksStreamProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isTeacher = user != null && RoleUtils.isTeacher(user.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by title or subject',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _semesterChip(null, 'All'),
                for (int s = 1; s <= 8; s++) _semesterChip(s, 'Sem $s'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: booksAsync.when(
              data: (books) {
                final filtered = books.where((b) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      b.title.toLowerCase().contains(_searchQuery) ||
                      b.subject.toLowerCase().contains(_searchQuery);
                  final matchesSemester =
                      _selectedSemester == null || b.semester == _selectedSemester;
                  return matchesSearch && matchesSemester;
                }).toList();

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _checkDownloaded(filtered));

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      books.isEmpty
                          ? 'No books uploaded yet.'
                          : 'No books match your search.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final book = filtered[index];
                    return BookCard(
                      book: book,
                      downloadProgress: _downloadProgress[book.bookId],
                      isDownloaded: _downloadedPaths.containsKey(book.bookId),
                      onRead: () => _openReader(book),
                      onDownload: () => _download(book),
                      onOpenDownloaded: () => _openReader(book, useLocal: true),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load books: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookUploadScreen()),
                );
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Book'),
            )
          : null,
    );
  }
}