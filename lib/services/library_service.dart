import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';

/// All Firestore + Storage + local-file logic for the E-Library module,
/// following the same "service wraps external calls" pattern as AuthService.
class LibraryService {
  final _booksRef = FirebaseFirestore.instance.collection('books');

  /// Live stream of all books, newest upload first.
  Stream<List<BookModel>> streamBooks() {
    return _booksRef
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookModel.fromDoc).toList());
  }

  /// Uploads a PDF to Firebase Storage under `library/`, then creates the
  /// matching Firestore `books` doc once the upload completes.
  Future<void> uploadBook({
    required String title,
    required String subject,
    required int semester,
    required File file,
    required String uploadedBy,
    required void Function(double progress) onProgress,
  }) async {
    final rawName = file.path.split(Platform.pathSeparator).last;
    final safeName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final storagePath =
        'library/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final ref = FirebaseStorage.instance.ref(storagePath);
    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    final completed = await uploadTask;
    final downloadUrl = await completed.ref.getDownloadURL();

    await _booksRef.add({
      'title': title,
      'subject': subject,
      'semester': semester,
      'fileUrl': downloadUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Downloads a book's PDF into app-private storage (no storage permission
  /// needed on any Android version) and reports progress as it streams in.
  Future<String> downloadBook(
    BookModel book, {
    required void Function(double progress) onProgress,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final libraryDir = Directory('${docsDir.path}/library_downloads');
    if (!libraryDir.existsSync()) {
      libraryDir.createSync(recursive: true);
    }

    final filePath = '${libraryDir.path}/${book.bookId}.pdf';
    final file = File(filePath);

    final request = http.Request('GET', Uri.parse(book.fileUrl));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();

    await response.stream.listen((chunk) {
      received += chunk.length;
      sink.add(chunk);
      if (total > 0) onProgress(received / total);
    }).asFuture();

    await sink.close();
    return filePath;
  }

  /// Returns the local path if this book was already downloaded, else null.
  Future<String?> getLocalPathIfExists(String bookId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final filePath = '${docsDir.path}/library_downloads/$bookId.pdf';
    return File(filePath).existsSync() ? filePath : null;
  }
}