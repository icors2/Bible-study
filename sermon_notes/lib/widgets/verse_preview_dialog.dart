import 'package:flutter/material.dart';

import '../services/bible_service.dart';

Future<void> showVersePreview(
  BuildContext context, {
  required String reference,
  required BibleService bible,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reference,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<PassageFetchResult>(
                    future: bible.fetchPassage(reference),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return SelectableText(
                          'Could not load this passage.\n\n${snap.error}',
                        );
                      }
                      final data = snap.data!;
                      if (data.verses.isEmpty) {
                        return SelectableText(data.text);
                      }
                      return ListView.separated(
                        itemCount: data.verses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final v = data.verses[i];
                          return SelectableText.rich(
                            TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: '${v.verse} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: v.text),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
