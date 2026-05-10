import 'package:flutter_test/flutter_test.dart';

import 'package:sermon_notes/models/sermon_models.dart';
import 'package:sermon_notes/services/outline_fetch_service.dart';

void main() {
  test('Calvary-style outline: major sections, preamble merged, blanks', () {
    final svc = OutlineFetchService();
    const raw = '''
How Jesus Taught Us to PrayMatthew 6:5–13
1.Jesus Begins with the _______________ Behind _______________
a.Prayer Is Not _______________
i.Matthew 6:6
2.Second point _______________
''';

    final sections = svc.buildSectionsFromPlainText(raw);

    expect(sections.length, 2);

    final blanks0 =
        sections[0].pieces.whereType<BlankPiece>().length;
    expect(blanks0, greaterThanOrEqualTo(2));

    expect(
      sections[0].pieces.whereType<TextPiece>().any(
            (t) => t.text.contains('a.Prayer'),
          ),
      isTrue,
    );

    final blanks1 =
        sections[1].pieces.whereType<BlankPiece>().length;
    expect(blanks1, greaterThanOrEqualTo(1));
  });

  test('splitMergedHeadingLine separates glued title and reference', () {
    const glued = 'How Jesus Taught Us to PrayMatthew 6:5–13';
    final split = OutlineFetchService.splitMergedHeadingLine(glued);
    expect(split.contains('\n'), isTrue);
    expect(split.contains('Matthew'), isTrue);
  });
}
