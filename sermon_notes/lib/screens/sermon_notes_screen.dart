import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sermon_models.dart';
import '../services/bible_service.dart';
import '../services/outline_fetch_service.dart';
import '../widgets/scripture_link_chips.dart';

class SermonNotesScreen extends StatefulWidget {
  const SermonNotesScreen({super.key, required this.bible});

  final BibleService bible;

  @override
  State<SermonNotesScreen> createState() => _SermonNotesScreenState();
}

class _SermonNotesScreenState extends State<SermonNotesScreen> {
  final _urlCtrl = TextEditingController();
  final _pasteCtrl = TextEditingController();
  final _fetcher = OutlineFetchService();

  List<SermonSection> _sections = [];
  final _blankControllers = <String, TextEditingController>{};
  final _notesControllers = <String, TextEditingController>{};

  bool _loading = false;
  String? _error;

  Timer? _saveDebounce;

  static const _prefsKey = 'sermon_draft_v1';
  static const _defaultOutlineUrl = 'https://calvaryeauclaire.org/notes';

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = SermonDraft.tryParse(prefs.getString(_prefsKey));
    if (!mounted) return;
    if (draft == null) {
      setState(() {
        if (_urlCtrl.text.isEmpty) {
          _urlCtrl.text = _defaultOutlineUrl;
        }
      });
      return;
    }
    _urlCtrl.text = (draft.sourceUrl != null &&
            draft.sourceUrl!.trim().isNotEmpty)
        ? draft.sourceUrl!.trim()
        : _defaultOutlineUrl;
    _pasteCtrl.text = draft.pastedPlainText ?? '';
    _sections = draft.sections;
    _rebindControllers();
    setState(() {});
  }

  void _rebindControllers() {
    for (final c in _blankControllers.values) {
      c.dispose();
    }
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    _blankControllers.clear();
    _notesControllers.clear();

    for (final s in _sections) {
      final notes = TextEditingController(text: s.notes);
      notes.addListener(_scheduleSave);
      _notesControllers[s.id] = notes;

      for (final p in s.pieces) {
        if (p is BlankPiece) {
          final ctrl = TextEditingController(text: p.value);
          ctrl.addListener(() {
            p.value = ctrl.text;
            _scheduleSave();
          });
          _blankControllers[p.id] = ctrl;
        }
      }
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _persistDraft);
  }

  Future<void> _persistDraft() async {
    for (final s in _sections) {
      s.notes = _notesControllers[s.id]?.text ?? s.notes;
    }
    final prefs = await SharedPreferences.getInstance();
    final draft = SermonDraft(
      sourceUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      pastedPlainText:
          _pasteCtrl.text.trim().isEmpty ? null : _pasteCtrl.text.trim(),
      sections: _sections,
    );
    await prefs.setString(_prefsKey, draft.serialize());
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (!mounted) return;
    setState(() {
      _sections = [];
      _error = null;
      _urlCtrl.text = _defaultOutlineUrl;
      _pasteCtrl.clear();
    });
    _rebindControllers();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _urlCtrl.dispose();
    _pasteCtrl.dispose();
    for (final c in _blankControllers.values) {
      c.dispose();
    }
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFromUrl() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plain = await _fetcher.fetchPlainText(_urlCtrl.text.trim());
      final sections = _fetcher.buildSectionsFromPlainText(plain);
      if (!mounted) return;
      setState(() {
        _sections = sections;
      });
      _rebindControllers();
      await _persistDraft();
    } on OutlineFetchException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString();
      if (kIsWeb) {
        msg =
            '$msg\n\nTip: many websites block browser requests (CORS). Use “Build from paste” with copied text, or run on Android.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _loadFromPaste() {
    FocusScope.of(context).unfocus();
    final plain = OutlineFetchService.plainFromUserPaste(_pasteCtrl.text);
    final sections = _fetcher.buildSectionsFromPlainText(plain);
    setState(() {
      _sections = sections;
      _error = null;
    });
    _rebindControllers();
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Sermon outline',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (kIsWeb)
                  Card(
                    margin: EdgeInsets.zero,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Web note'),
                      subtitle: Text(
                        'Loading outlines from other sites often fails in the browser because of CORS. Paste usually works; Android has fewer limits.',
                      ),
                    ),
                  ),
                if (kIsWeb) const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Outline URL',
                    hintText: _defaultOutlineUrl,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _loading ? null : _loadFromUrl,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: const Text('Load from URL'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _sections.isEmpty ? null : _clearDraft,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pasteCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Or paste outline (plain text or HTML)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loadFromPaste,
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Build from paste'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_sections.isEmpty)
                  Text(
                    'Load an outline to see fill-in blanks and notes for each point.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ]),
            ),
          ),
          if (_sections.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = _sections[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _SectionCard(
                        index: index + 1,
                        section: section,
                        blankControllers: _blankControllers,
                        notesController: _notesControllers[section.id]!,
                        bible: widget.bible,
                      ),
                    );
                  },
                  childCount: _sections.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.index,
    required this.section,
    required this.blankControllers,
    required this.notesController,
    required this.bible,
  });

  final int index;
  final SermonSection section;
  final Map<String, TextEditingController> blankControllers;
  final TextEditingController notesController;
  final BibleService bible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Point $index',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                for (final p in section.pieces)
                  if (p is TextPiece)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(
                        p.text,
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  else if (p is BlankPiece)
                    SizedBox(
                      width: 148,
                      child: TextField(
                        controller: blankControllers[p.id],
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          hintText: 'Blank',
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Notes',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: notesController,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText:
                    'Reflections, quotes, cross-references… (try John 3:16)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: notesController,
              builder: (context, value, _) {
                return ScriptureLinkChips(
                  text: value.text,
                  bible: bible,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
