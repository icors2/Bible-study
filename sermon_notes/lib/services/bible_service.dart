import 'dart:convert';

import 'package:http/http.dart' as http;

class BibleBook {
  BibleBook({required this.id, required this.name});

  final String id;
  final String name;

  static BibleBook fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class BibleVerse {
  BibleVerse({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  final String bookName;
  final int chapter;
  final int verse;
  final String text;
}

class PassageFetchResult {
  PassageFetchResult({
    required this.reference,
    required this.text,
    required this.verses,
  });

  final String reference;
  final String text;
  final List<BibleVerse> verses;
}

/// Uses bible-api.com (public domain WEB text by default).
class BibleService {
  BibleService({http.Client? client, this.translation = 'web'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String translation;

  static const _base = 'https://bible-api.com';

  Future<List<BibleBook>> fetchBooks() async {
    final uri = Uri.parse('$_base/data/$translation');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BibleServiceException('Could not load Bible books (${res.statusCode}).');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final books = (map['books'] as List<dynamic>? ?? [])
        .map((e) => BibleBook.fromJson(e as Map<String, dynamic>))
        .toList();
    return books;
  }

  Future<PassageFetchResult> fetchPassage(String humanReference) async {
    final q = _toQuery(humanReference);
    final uri = Uri.parse('$_base/$q?translation=$translation');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BibleServiceException(
        'Could not load "$humanReference" (${res.statusCode}).',
      );
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final ref = map['reference'] as String? ?? humanReference;
    final text = (map['text'] as String? ?? '').trim();
    final verses = (map['verses'] as List<dynamic>? ?? []).map((v) {
      final m = v as Map<String, dynamic>;
      return BibleVerse(
        bookName: m['book_name'] as String? ?? '',
        chapter: (m['chapter'] as num?)?.toInt() ?? 0,
        verse: (m['verse'] as num?)?.toInt() ?? 0,
        text: (m['text'] as String? ?? '').trim(),
      );
    }).toList();
    return PassageFetchResult(reference: ref, text: text, verses: verses);
  }

  Future<PassageFetchResult> fetchChapter(String bookName, int chapter) {
    final query = '${bookName.trim()}+$chapter';
    return fetchPassage(query);
  }

  /// Returns chapter numbers available for a book id (e.g. GEN → 1..50).
  Future<List<int>> fetchChapterNumbersForBookId(String bookId) async {
    final uri = Uri.parse('$_base/data/$translation/$bookId');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BibleServiceException(
        'Could not load chapters (${res.statusCode}).',
      );
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final ch = (map['chapters'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return (m['chapter'] as num?)?.toInt() ?? 0;
        })
        .where((n) => n > 0)
        .toList();
    ch.sort();
    return ch;
  }

  String _toQuery(String ref) {
    final trimmed = ref.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .replaceAll(RegExp(r'\s+'), '+')
        .replaceAll(RegExp(r'\+{2,}'), '+');
  }
}

class BibleServiceException implements Exception {
  BibleServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
