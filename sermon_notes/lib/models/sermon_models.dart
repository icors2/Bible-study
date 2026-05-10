import 'dart:convert';

/// A single outline block (e.g. one numbered point with optional sub-lines).
class SermonSection {
  SermonSection({
    required this.id,
    required this.pieces,
    this.notes = '',
  });

  final String id;
  final List<InlinePiece> pieces;
  String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'notes': notes,
        'pieces': pieces.map((p) => p.toJson()).toList(),
      };

  static SermonSection fromJson(Map<String, dynamic> json) {
    final rawPieces = json['pieces'] as List<dynamic>? ?? [];
    return SermonSection(
      id: json['id'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      pieces: rawPieces
          .map((e) => InlinePiece.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

sealed class InlinePiece {
  Map<String, dynamic> toJson();

  static InlinePiece fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'text':
        return TextPiece(json['text'] as String? ?? '');
      case 'blank':
        return BlankPiece(
          id: json['id'] as String? ?? '',
          value: json['value'] as String? ?? '',
        );
      default:
        return TextPiece('');
    }
  }
}

class TextPiece extends InlinePiece {
  TextPiece(this.text);

  final String text;

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

class BlankPiece extends InlinePiece {
  BlankPiece({required this.id, this.value = ''});

  final String id;
  String value;

  @override
  Map<String, dynamic> toJson() => {'type': 'blank', 'id': id, 'value': value};
}

/// Persisted working state for the sermon tab.
class SermonDraft {
  SermonDraft({
    this.sourceUrl,
    this.pastedPlainText,
    required this.sections,
  });

  final String? sourceUrl;
  final String? pastedPlainText;
  final List<SermonSection> sections;

  Map<String, dynamic> toJson() => {
        'sourceUrl': sourceUrl,
        'pastedPlainText': pastedPlainText,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  static SermonDraft? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final secs = (map['sections'] as List<dynamic>? ?? [])
          .map((e) => SermonSection.fromJson(e as Map<String, dynamic>))
          .toList();
      return SermonDraft(
        sourceUrl: map['sourceUrl'] as String?,
        pastedPlainText: map['pastedPlainText'] as String?,
        sections: secs,
      );
    } catch (_) {
      return null;
    }
  }

  String serialize() => jsonEncode(toJson());
}
