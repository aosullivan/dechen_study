import 'dart:convert';
import 'dart:math';
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

/// Loads pre-parsed bcv data from bcv_parsed.json (built by tools/build_bcv_parsed.dart).
class BcvVerseService {
  BcvVerseService._();
  static final BcvVerseService _instance = BcvVerseService._();
  static BcvVerseService get instance => _instance;

  List<String>? _verses;
  List<String?>? _captions;
  List<String?>? _refs;
  List<BcvChapter>? _chapters;
  static const String _assetPath = 'texts/bcv_parsed.json';

  /// Matches a base verse ref like "1.5" (no suffix). Shared across the app.
  static final RegExp baseVerseRefPattern = RegExp(r'^\d+\.\d+$');

  /// Matches a trailing segment suffix like "ab", "cd", "a", "bcd".
  static final RegExp segmentSuffixPattern = RegExp(r'[a-d]+$');

  /// Pre-warm: start loading and parsing the asset so it's ready when the read screen opens.
  Future<void> preload() => _ensureLoaded();

  /// Loads pre-parsed JSON and caches. Idempotent.
  Future<void> _ensureLoaded() async {
    if (_verses != null) return;
    final content = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(content) as Map<String, dynamic>;
    _verses = (json['verses'] as List<dynamic>).cast<String>();
    _captions = (json['captions'] as List<dynamic>)
        .map((e) => e == null ? null : e as String)
        .toList();
    _refs = (json['refs'] as List<dynamic>)
        .map((e) => e == null ? null : e as String)
        .toList();
    final chList = json['chapters'] as List<dynamic>;
    _chapters = chList
        .map((c) => BcvChapter(
              number: c['number'] as int,
              title: c['title'] as String,
              startVerseIndex: c['startVerseIndex'] as int,
              endVerseIndex: c['endVerseIndex'] as int,
            ))
        .toList();
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
