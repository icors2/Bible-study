import 'package:flutter/material.dart';

import '../services/bible_service.dart';
import '../utils/scripture_references.dart';
import 'verse_preview_dialog.dart';

/// Shows tappable chips for scripture references detected in [text].
class ScriptureLinkChips extends StatelessWidget {
  const ScriptureLinkChips({
    super.key,
    required this.text,
    required this.bible,
  });

  final String text;
  final BibleService bible;

  @override
  Widget build(BuildContext context) {
    final refs = ScriptureReferences.findReferences(text);
    if (refs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scripture links',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in refs)
                ActionChip(
                  label: Text(r),
                  onPressed: () => showVersePreview(
                    context,
                    reference: r,
                    bible: bible,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
