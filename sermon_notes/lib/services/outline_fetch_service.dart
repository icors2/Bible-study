import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/sermon_models.dart';

/// Fetches a page and turns visible HTML into plain text with reasonable breaks.
class OutlineFetchService {
  OutlineFetchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent =
      'Mozilla/5.0 (compatible; SermonNotes/1.0; +https://flutter.dev)';

  Future<String> fetchPlainText(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw OutlineFetchException('Invalid URL.');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw OutlineFetchException('Only http(s) URLs are supported.');
    }

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OutlineFetchException(
        'Could not load page (HTTP ${response.statusCode}).',
      );
    }

    final charsetPart = response.headers['content-type']
        ?.split(';')
        .map((e) => e.trim().toLowerCase())
        .firstWhere(
          (e) => e.startsWith('charset='),
          orElse: () => '',
        );
    final encodingName =
        (charsetPart == null || charsetPart.isEmpty)
            ? null
            : charsetPart.replaceFirst('charset=', '').trim();

    String html;
    try {
      if (encodingName != null && encodingName.isNotEmpty) {
        html = Encoding.getByName(encodingName)?.decode(response.bodyBytes) ??
            utf8.decode(response.bodyBytes, allowMalformed: true);
      } else {
        html = utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    } catch (_) {
      html = response.body;
    }

    return htmlToPlainText(html);
  }

  /// Converts pasted or fetched HTML / plain text into outline sections.
  List<SermonSection> buildSectionsFromPlainText(String plain) {
    final lines = plain
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return [];
    }

    final blocks = _groupOutlineLines(lines);
    var blankCounter = 0;
    String nextBlankId() => 'b${blankCounter++}';

    return [
      for (var i = 0; i < blocks.length; i++)
        SermonSection(
          id: 's$i',
          pieces: _parseBlanksInText(blocks[i], nextBlankId),
        ),
    ];
  }

  static String htmlToPlainText(String html) {
    var normalized = html
        .replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'</(p|div|h[1-6]|li|tr)\s*>', caseSensitive: false),
            '\n');

    final doc = html_parser.parse(normalized);
    final body = doc.body;
    if (body == null) {
      return _collapseWhitespace(doc.documentElement?.text ?? '');
    }
    return _collapseWhitespace(body.text);
  }

  /// Plain text or HTML pasted by the user.
  static String plainFromUserPaste(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final looksLikeHtml = RegExp(r'<[a-zA-Z][\s\S]*?>').hasMatch(t);
    if (looksLikeHtml) {
      return htmlToPlainText(t);
    }
    return _collapseWhitespace(t);
  }

  static String _collapseWhitespace(String input) {
    return input
        .replaceAll('\u00a0', ' ')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
  }
}

class OutlineFetchException implements Exception {
  OutlineFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

final _outlineLineStart = RegExp(
  r'^\s*(?:\d{1,3}|[a-z]|[ivxlcdm]{1,8})[\.\)]\s',
  caseSensitive: false,
);

List<String> _groupOutlineLines(List<String> lines) {
  final blocks = <String>[];
  final buf = StringBuffer();

  void flush() {
    final s = buf.toString().trim();
    if (s.isNotEmpty) blocks.add(s);
    buf.clear();
  }

  for (final line in lines) {
    if (_outlineLineStart.hasMatch(line) && buf.isNotEmpty) {
      flush();
    }
    if (buf.isNotEmpty) buf.writeln();
    buf.write(line);
  }
  flush();

  if (blocks.length <= 1 && lines.length > 8) {
    return lines;
  }
  return blocks.isEmpty ? [lines.join('\n')] : blocks;
}

final _blankPattern = RegExp(r'_{3,}|\.{5,}|…{3,}');

List<InlinePiece> _parseBlanksInText(String text, String Function() nextId) {
  final pieces = <InlinePiece>[];
  var start = 0;
  for (final m in _blankPattern.allMatches(text)) {
    if (m.start > start) {
      final t = text.substring(start, m.start);
      if (t.isNotEmpty) pieces.add(TextPiece(t));
    }
    pieces.add(BlankPiece(id: nextId()));
    start = m.end;
  }
  if (start < text.length) {
    final tail = text.substring(start);
    if (tail.isNotEmpty) pieces.add(TextPiece(tail));
  }
  if (pieces.isEmpty) {
    return [TextPiece(text)];
  }
  return pieces;
}
