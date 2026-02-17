import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One chapter: number, title, and verse index range into the flat verse list.
class BcvChapter {
  const BcvChapter({
    required this.number,
    required this.title,
    required this.startVerseIndex,
    required this.endVerseIndex,
  });
  final int number;
  final String title;
  final int startVerseIndex;
  final int endVerseIndex;
}

/// Result of parsing the bcv-root asset in a background isolate.
class _ParseResult {
  _ParseResult({
    required this.verses,
    required this.captions,
    required this.refs,
    required this.chapters,
  });
  final List<String> verses;
  final List<String?> captions;
  final List<String?> refs;
  final List<BcvChapter> chapters;
}

/// Top-level so it can run in a compute isolate.
_ParseResult _parseBcvRoot(String content) {
  final chapterTitleOnly = RegExp(r'^Chapter (\d+):\s*(.+)\s*$');
  final verseRefPattern = RegExp(r'\[(\d+)\.(\d+)\]');

  String? extractCaption(String block) {
    final match = verseRefPattern.allMatches(block).lastOrNull;
    if (match == null) return null;
    return 'Chapter ${match.group(1)}, Verse ${match.group(2)}';
  }

  String? extractRef(String block) {
    final match = verseRefPattern.allMatches(block).lastOrNull;
    if (match == null) return null;
    return '${match.group(1)}.${match.group(2)}';
  }

  // Strip BOM and form-feed
  content = content.replaceAll(RegExp(r'[\uFEFF\x0C]'), '');
  // Normalize line endings
  content = content.replaceAll(RegExp(r'\r\n?'), '\n');
  final blocks = content.split(RegExp(r'\n\s*\n'));
  final verses = <String>[];
  final captions = <String?>[];
  final refs = <String?>[];
  final chapterStarts = <List<dynamic>>[];
  for (final block in blocks) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) continue;
    final lines = trimmed
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    var pendingVerseLines = <String>[];
    for (final line in lines) {
      final chapterMatch = chapterTitleOnly.firstMatch(line);
      if (chapterMatch != null) {
        if (pendingVerseLines.isNotEmpty) {
          final joined = pendingVerseLines.join('\n');
          verses.add(joined);
          captions.add(extractCaption(joined));
          refs.add(extractRef(joined));
          pendingVerseLines = [];
        }
        chapterStarts.add([
          int.parse(chapterMatch.group(1)!),
          chapterMatch.group(2)!.trim(),
          verses.length,
        ]);
        continue;
      }
      pendingVerseLines.add(line);
    }
    if (pendingVerseLines.isNotEmpty) {
      final joined = pendingVerseLines.join('\n');
      verses.add(joined);
      captions.add(extractCaption(joined));
      refs.add(extractRef(joined));
    }
  }
  // Build chapters
  final chapters = <BcvChapter>[];
  for (var i = 0; i < chapterStarts.length; i++) {
    final start = chapterStarts[i];
    final endIndex = i + 1 < chapterStarts.length
        ? chapterStarts[i + 1][2] as int
        : verses.length;
    chapters.add(BcvChapter(
      number: start[0] as int,
      title: start[1] as String,
      startVerseIndex: start[2] as int,
      endVerseIndex: endIndex,
    ));
  }
  return _ParseResult(
    verses: verses,
    captions: captions,
    refs: refs,
    chapters: chapters,
  );
}

/// Loads and parses the bcv-root asset, caches verses and chapters, and provides random verse selection.
class BcvVerseService {
  BcvVerseService._();
  static final BcvVerseService _instance = BcvVerseService._();
  static BcvVerseService get instance => _instance;

  List<String>? _verses;
  List<String?>? _captions;
  List<String?>? _refs;
  List<BcvChapter>? _chapters;
  static const String _assetPath = 'texts/bcv-root';

  /// Matches a base verse ref like "1.5" (no suffix). Shared across the app.
  static final RegExp baseVerseRefPattern = RegExp(r'^\d+\.\d+$');

  /// Matches a trailing segment suffix like "ab", "cd", "a", "bcd".
  static final RegExp segmentSuffixPattern = RegExp(r'[a-d]+$');

  /// Loads the asset, parses in a background isolate, and caches. Idempotent.
  Future<void> _ensureLoaded() async {
    if (_verses != null) return;
    final content = await rootBundle.loadString(_assetPath);
    final result = await compute(_parseBcvRoot, content);
    _verses = result.verses;
    _captions = result.captions;
    _refs = result.refs;
    _chapters = result.chapters;
  }

  /// Returns a random verse text. Loads and parses asset on first call.
  Future<String> getRandomVerse() async {
    await _ensureLoaded();
    final list = _verses!;
    if (list.isEmpty) return '';
    final index = Random().nextInt(list.length);
    return list[index];
  }

  /// Returns the caption for the verse at [index] (e.g. "Chapter 1, Verse 1"), or null.
  String? getVerseCaption(int index) {
    if (_captions == null || index < 0 || index >= _captions!.length) return null;
    return _captions![index];
  }

  /// Returns the verse ref at [index] (e.g. "1.5"), or null if the verse has no [c.v] marker.
  String? getVerseRef(int index) {
    if (_refs == null || index < 0 || index >= _refs!.length) return null;
    return _refs![index];
  }

  /// Returns the first verse index whose ref equals [ref] (e.g. "1.5"), or null.
  int? getIndexForRef(String ref) {
    if (_refs == null) return null;
    for (var i = 0; i < _refs!.length; i++) {
      if (_refs![i] == ref) return i;
    }
    return null;
  }

  /// Like [getIndexForRef] but also tries stripping segment suffixes (ab, cd, etc.)
  /// so "8.19ab" falls back to "8.19".
  int? getIndexForRefWithFallback(String ref) {
    var i = getIndexForRef(ref);
    if (i == null && segmentSuffixPattern.hasMatch(ref)) {
      i = getIndexForRef(ref.replaceAll(segmentSuffixPattern, ''));
    }
    return i;
  }

  /// Returns the verse text at [index], or null if out of range.
  String? getVerseAt(int index) {
    if (_verses == null || index < 0 || index >= _verses!.length) return null;
    return _verses![index];
  }

  /// Returns chapters (title and verse index ranges). Loads and parses asset on first call.
  Future<List<BcvChapter>> getChapters() async {
    await _ensureLoaded();
    if (_chapters == null) return [];
    return List.unmodifiable(_chapters!);
  }

  /// Returns the flat list of verse strings. Call after getChapters() or getRandomVerseWithCaption() so data is loaded.
  List<String> getVerses() => List.unmodifiable(_verses ?? []);

  /// Returns a random verse and its caption. Caption may be null. Includes verseIndex for deep link.
  Future<BcvVerseResult> getRandomVerseWithCaption() async {
    await _ensureLoaded();
    final list = _verses!;
    if (list.isEmpty) return BcvVerseResult(verse: '', caption: null, verseIndex: null);
    final index = Random().nextInt(list.length);
    return BcvVerseResult(
      verse: list[index],
      caption: _captions![index],
      verseIndex: index,
    );
  }
}

class BcvVerseResult {
  const BcvVerseResult({
    required this.verse,
    this.caption,
    this.verseIndex,
  });
  final String verse;
  final String? caption;
  final int? verseIndex;
}
