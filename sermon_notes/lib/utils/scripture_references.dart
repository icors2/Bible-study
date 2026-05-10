/// Detects references like "John 3:16" or "1 Samuel 1:1-3" in free text.
class ScriptureReferences {
  ScriptureReferences._();

  /// Longest names first so "1 Corinthians" wins over "Corinthians".
  static final List<String> _books = () {
    const names = [
      'Song of Solomon',
      '1 Corinthians',
      '2 Corinthians',
      '1 Thessalonians',
      '2 Thessalonians',
      '1 Timothy',
      '2 Timothy',
      '1 Peter',
      '2 Peter',
      '1 John',
      '2 John',
      '3 John',
      '1 Samuel',
      '2 Samuel',
      '1 Kings',
      '2 Kings',
      '1 Chronicles',
      '2 Chronicles',
      'Deuteronomy',
      'Lamentations',
      'Ecclesiastes',
      'Philippians',
      'Colossians',
      'Galatians',
      'Genesis',
      'Exodus',
      'Leviticus',
      'Numbers',
      'Joshua',
      'Judges',
      'Ruth',
      'Ezra',
      'Nehemiah',
      'Esther',
      'Job',
      'Psalms',
      'Psalm',
      'Proverbs',
      'Isaiah',
      'Jeremiah',
      'Ezekiel',
      'Daniel',
      'Hosea',
      'Joel',
      'Amos',
      'Obadiah',
      'Jonah',
      'Micah',
      'Nahum',
      'Habakkuk',
      'Zephaniah',
      'Haggai',
      'Zechariah',
      'Malachi',
      'Matthew',
      'Mark',
      'Luke',
      'John',
      'Acts',
      'Romans',
      'Ephesians',
      'Titus',
      'Philemon',
      'Hebrews',
      'James',
      'Jude',
      'Revelation',
    ];
    final sorted = [...names]..sort((a, b) => b.length.compareTo(a.length));
    return sorted;
  }();

  static final RegExp pattern = () {
    final escaped = _books.map(RegExp.escape).join('|');
    return RegExp(
      r'\b((?:[1-3]\s+)?(?:' +
          escaped +
          r'))\s+(\d+)\s*:\s*(\d+)(?:\s*[-–—]\s*(\d+))?\b',
      caseSensitive: false,
    );
  }();

  /// Unique references in first-seen order.
  static List<String> findReferences(String input) {
    final seen = <String>{};
    final out = <String>[];
    for (final m in pattern.allMatches(input)) {
      final book = m.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      final chapter = m.group(2)!;
      final verseStart = m.group(3)!;
      final verseEnd = m.group(4);
      final ref = verseEnd == null
          ? '$book $chapter:$verseStart'
          : '$book $chapter:$verseStart-$verseEnd';
      if (seen.add(ref)) {
        out.add(ref);
      }
    }
    return out;
  }
}
