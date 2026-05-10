import 'package:flutter/material.dart';

import '../services/bible_service.dart';
import '../widgets/verse_preview_dialog.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key, required this.bible});

  final BibleService bible;

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  List<BibleBook>? _books;
  BibleBook? _book;
  List<int> _chapters = [];
  int _chapter = 1;

  PassageFetchResult? _passage;
  Object? _error;
  bool _loadingBooks = true;
  bool _loadingChapter = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loadingBooks = true;
      _error = null;
    });
    try {
      final books = await widget.bible.fetchBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _book = books.isNotEmpty ? books.first : null;
        _loadingBooks = false;
      });
      if (_book != null) {
        await _loadChaptersForBook(_book!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loadingBooks = false;
      });
    }
  }

  Future<void> _loadChaptersForBook(BibleBook book) async {
    setState(() {
      _loadingChapter = true;
      _error = null;
    });
    try {
      final ch = await widget.bible.fetchChapterNumbersForBookId(book.id);
      if (!mounted) return;
      setState(() {
        _chapters = ch;
        _chapter = ch.isNotEmpty ? ch.first : 1;
        _loadingChapter = false;
      });
      await _loadChapterText();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loadingChapter = false;
      });
    }
  }

  Future<void> _loadChapterText() async {
    final book = _book;
    if (book == null) return;
    setState(() {
      _loadingChapter = true;
      _error = null;
    });
    try {
      final passage = await widget.bible.fetchChapter(book.name, _chapter);
      if (!mounted) return;
      setState(() {
        _passage = passage;
        _loadingChapter = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loadingChapter = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _books == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText('Could not load Bible data.\n\n$_error'),
        ),
      );
    }

    final books = _books ?? [];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Bible',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<BibleBook>(
                    value: _book,
                    decoration: const InputDecoration(
                      labelText: 'Book',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final b in books)
                        DropdownMenuItem(
                          value: b,
                          child: Text(
                            b.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (b) async {
                      if (b == null) return;
                      setState(() => _book = b);
                      await _loadChaptersForBook(b);
                    },
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _chapters.isEmpty
                      ? const InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Chapter',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text('—'),
                        )
                      : DropdownButtonFormField<int>(
                          value: _chapters.contains(_chapter)
                              ? _chapter
                              : _chapters.first,
                          decoration: const InputDecoration(
                            labelText: 'Chapter',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            for (final c in _chapters)
                              DropdownMenuItem(
                                value: c,
                                child: Text('$c'),
                              ),
                          ],
                          onChanged: (c) async {
                            if (c == null) return;
                            setState(() => _chapter = c);
                            await _loadChapterText();
                          },
                        ),
                ),
                FilledButton.icon(
                  onPressed: _loadingChapter ? null : _loadChapterText,
                  icon: _loadingChapter
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SelectableText(
                _error.toString(),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const Divider(height: 24),
          Expanded(
            child: _passage == null
                ? const Center(child: Text('Select a book and chapter.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _passage!.verses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final v = _passage!.verses[i];
                      final ref = '${v.bookName} ${v.chapter}:${v.verse}';
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => showVersePreview(
                          context,
                          reference: ref,
                          bible: widget.bible,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${v.verse}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                v.text,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
