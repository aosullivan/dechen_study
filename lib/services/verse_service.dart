import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import '../config/study_text_config.dart';

/// One chapter: number, title, and verse index range into the flat verse list.
class Chapter {
  const Chapter({
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

class _VerseCache {
  _VerseCache({
    required this.verses,
    required this.captions,
    required this.refs,
    required this.refToIndex,
    required this.chapters,
  });
  final List<String> verses;
  final List<String?> captions;
  final List<String?> refs;
  final Map<String, int> refToIndex;
  final List<Chapter> chapters;
}

/// Loads pre-parsed verse data from JSON (built by tools/build_bcv_parsed.dart for BCV).
/// Data is keyed by textId; paths come from [StudyTextConfig].
class VerseService {
  VerseService._();
  static final VerseService _instance = VerseService._();
  static VerseService get instance => _instance;

  final Map<String, _VerseCache> _cache = {};

  /// Matches a base verse ref like "1.5" (no suffix). Shared across the app.
  static final RegExp baseVerseRefPattern = RegExp(r'^\d+\.\d+$');

  /// Matches a trailing segment suffix like "ab", "cd", "a", "bcd", "abc".
  static final RegExp segmentSuffixPattern = RegExp(r'[a-d]+$');

  /// Returns the inclusive [start, end] line range for a segmented ref.
  ///
  /// Letters map to canonical 0-based positions:
  ///   a=0, b=1, c=2, d=3
  ///
  /// The suffix must be a non-empty, contiguous run of letters from {a..d}
  /// (e.g. "a", "ab", "bc", "cd", "abc", "bcd"). Non-contiguous
  /// suffixes (e.g. "ac", "bd") and unknown characters return null.
  ///
  /// If the verse has at least as many lines as the highest referenced letter
  /// slot, the positions are used directly. Otherwise the range is scaled
  /// proportionally across the available line count.
  static List<int>? lineRangeForSegmentRef(String ref, int lineCount) {
    if (lineCount <= 0) return null;
    final m = RegExp(r'([a-d]+)$', caseSensitive: false).firstMatch(ref);
    if (m == null) return null;
    final suffix = m.group(1)!.toLowerCase();
    if (suffix.isEmpty) return null;

    const slots = 'abcd';
    final letterPos = <String, int>{
      for (var i = 0; i < slots.length; i++) slots[i]: i,
    };

    // Validate: all chars known and strictly contiguous.
    for (var i = 0; i < suffix.length; i++) {
      if (!letterPos.containsKey(suffix[i])) return null;
      if (i > 0 && letterPos[suffix[i]]! != letterPos[suffix[i - 1]]! + 1) {
        return null;
      }
    }

    final firstPos = letterPos[suffix[0]]!;
    final lastPos = letterPos[suffix[suffix.length - 1]]!;
    const slotCount = 4;

    int start, end;
    if (lineCount >= slotCount) {
      start = firstPos;
      end = lastPos;
    } else {
      // Scale canonical positions into the actual line count.
      start = (firstPos * lineCount ~/ slotCount).clamp(0, lineCount - 1);
      end = (((lastPos + 1) * lineCount + slotCount - 1) ~/ slotCount - 1)
          .clamp(0, lineCount - 1);
      if (start > end) end = start;
    }

    return [start, end];
  }

  String? _assetPathFor(String textId) {
    return getStudyText(textId)?.parsedJsonPath;
  }

  /// Pre-warm: start loading and parsing the asset for [textId].
  Future<void> preload(String textId) => _ensureLoaded(textId);

  Future<void> _ensureLoaded(String textId) async {
    if (_cache.containsKey(textId)) return;
    final path = _assetPathFor(textId);
    if (path == null || path.isEmpty) return;
    try {
      final content = await rootBundle.loadString(path);
      final json = jsonDecode(content) as Map<String, dynamic>;
      final verses = (json['verses'] as List<dynamic>).cast<String>();
      final captions = (json['captions'] as List<dynamic>)
          .map((e) => e == null ? null : e as String)
          .toList();
      final refs = (json['refs'] as List<dynamic>)
          .map((e) => e == null ? null : e as String)
          .toList();
      final refToIndex = <String, int>{};
      for (var i = 0; i < refs.length; i++) {
        final ref = refs[i];
        if (ref != null && ref.isNotEmpty) {
          refToIndex[ref] = i;
        }
      }
      final chList = json['chapters'] as List<dynamic>;
      final chapters = chList
          .map((c) => Chapter(
                number: c['number'] as int,
                title: c['title'] as String,
                startVerseIndex: c['startVerseIndex'] as int,
                endVerseIndex: c['endVerseIndex'] as int,
              ))
          .toList();
      _cache[textId] = _VerseCache(
        verses: verses,
        captions: captions,
        refs: refs,
        refToIndex: refToIndex,
        chapters: chapters,
      );
    } catch (_) {
      // Leave uncached so callers can handle missing text
    }
  }

  _VerseCache? _get(String textId) => _cache[textId];

  /// Returns a random verse text for [textId]. Loads and parses asset on first call.
  Future<String> getRandomVerse(String textId) async {
    await _ensureLoaded(textId);
    final c = _get(textId);
    if (c == null || c.verses.isEmpty) return '';
    final index = Random().nextInt(c.verses.length);
    return c.verses[index];
  }

  /// Returns the caption for the verse at [index] (e.g. "Chapter 1, Verse 1"), or null.
  String? getVerseCaption(String textId, int index) {
    final c = _get(textId);
    if (c == null || index < 0 || index >= c.captions.length) return null;
    return c.captions[index];
  }

  /// Returns the verse ref at [index] (e.g. "1.5"), or null if the verse has no [c.v] marker.
  String? getVerseRef(String textId, int index) {
    final c = _get(textId);
    if (c == null || index < 0 || index >= c.refs.length) return null;
    return c.refs[index];
  }

  /// Returns the first verse index whose ref equals [ref] (e.g. "1.5"), or null.
  int? getIndexForRef(String textId, String ref) {
    return _get(textId)?.refToIndex[ref];
  }

  /// Like [getIndexForRef] but also tries stripping segment suffixes (ab, cd, etc.)
  /// so "8.19ab" falls back to "8.19".
  int? getIndexForRefWithFallback(String textId, String ref) {
    var i = getIndexForRef(textId, ref);
    if (i == null && segmentSuffixPattern.hasMatch(ref)) {
      i = getIndexForRef(textId, ref.replaceAll(segmentSuffixPattern, ''));
    }
    return i;
  }

  /// Returns the verse text at [index], or null if out of range.
  String? getVerseAt(String textId, int index) {
    final c = _get(textId);
    if (c == null || index < 0 || index >= c.verses.length) return null;
    return c.verses[index];
  }

  /// Returns chapters (title and verse index ranges) for [textId].
  Future<List<Chapter>> getChapters(String textId) async {
    await _ensureLoaded(textId);
    final c = _get(textId);
    if (c == null) return [];
    return List.unmodifiable(c.chapters);
  }

  /// Returns the flat list of verse strings for [textId]. Call after getChapters or getRandomVerseWithCaption so data is loaded.
  List<String> getVerses(String textId) {
    final c = _get(textId);
    return c == null ? [] : List.unmodifiable(c.verses);
  }

  /// Returns a random verse and its caption for [textId]. Caption may be null. Includes verseIndex for deep link.
  Future<VerseResult> getRandomVerseWithCaption(String textId) async {
    await _ensureLoaded(textId);
    final c = _get(textId);
    if (c == null || c.verses.isEmpty) {
      return VerseResult(verse: '', caption: null, verseIndex: null);
    }
    final index = Random().nextInt(c.verses.length);
    return VerseResult(
      verse: c.verses[index],
      caption: c.captions[index],
      verseIndex: index,
    );
  }
}

class VerseResult {
  const VerseResult({
    required this.verse,
    this.caption,
    this.verseIndex,
  });
  final String verse;
  final String? caption;
  final int? verseIndex;
}
