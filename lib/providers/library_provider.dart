import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_model.dart';
import '../services/library_service.dart';

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryService();
});

/// Live list of all books — screens filter this locally for search/semester.
final booksStreamProvider = StreamProvider<List<BookModel>>((ref) {
  return ref.watch(libraryServiceProvider).streamBooks();
});