import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One commentary block: the list of verse refs it covers and the commentary text.
class CommentaryEntry {
  const CommentaryEntry({
    required this.refsInBlock,
    required this.commentaryText,
  });
  final List<String> refsInBlock;
  final String commentaryText;
}

/// Top-level so it can run in a compute isolate.
({
  Map<String, List<String>> refToRefsInBlock,
  Map<String, String> refToCommentary,
  List<CommentaryEntry> allSections
}) _parseCommentary(String content) {
  // Detects a section header line: any line starting with [chapter.verse (e.g. [1.32], [1.4ab], [1.34-1.35ab])
  final sectionHeader = RegExp(r'^\[\d+\.');
  // Extracts verse refs from a header, handling ranges like [1.34-1.35ab] → ["1.34", "1.35ab"]
  final refExtract = RegExp(r'(?:\[|-)(\d+\.\d+[a-z]*)');
  int suffixRank(String suffix) {
    switch (suffix) {
      case '':
        return 0;
      case 'a':
      case 'ab':
        return 1;
      case 'bcd':
      case 'cd':
        return 2;
      default:
        return 3;
    }
  }

  (int, int, int, String)? parseRef(String ref) {
    final m =
        RegExp(r'^(\d+)\.(\d+)([a-z]*)$', caseSensitive: false).firstMatch(ref);
    if (m == null) return null;
    final ch = int.tryParse(m.group(1)!);
    final verse = int.tryParse(m.group(2)!);
    if (ch == null || verse == null) return null;
    final suffix = (m.group(3) ?? '').toLowerCase();
    return (ch, verse, suffixRank(suffix), suffix);
  }

  int compareRefs(String a, String b) {
    final pa = parseRef(a);
    final pb = parseRef(b);
    if (pa == null || pb == null) return a.compareTo(b);
    if (pa.$1 != pb.$1) return pa.$1.compareTo(pb.$1);
    if (pa.$2 != pb.$2) return pa.$2.compareTo(pb.$2);
    if (pa.$3 != pb.$3) return pa.$3.compareTo(pb.$3);
    return pa.$4.compareTo(pb.$4);
  }

  final refToRefsInBlock = <String, List<String>>{};
  final refToCommentary = <String, String>{};
  final allSections = <CommentaryEntry>[];
  final lines = content.split('\n');
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (!sectionHeader.hasMatch(line)) {
      i++;
      continue;
    }
    final refs = refExtract.allMatches(line).map((m) => m.group(1)!).toList();
    if (refs.isEmpty) {
      i++;
      continue;
    }
    final refsDeduped = refs.toSet().toList()..sort(compareRefs);
    final bodyLines = <String>[];
    i++;
    while (i < lines.length) {
      final next = lines[i];
      if (sectionHeader.hasMatch(next)) break;
      bodyLines.add(next);
      i++;
    }
    final commentaryText = bodyLines.join('\n').trim();
    final entry = CommentaryEntry(
        refsInBlock: refsDeduped, commentaryText: commentaryText);
    allSections.add(entry);
    for (final ref in refsDeduped) {
      refToRefsInBlock[ref] = refsDeduped;
      refToCommentary[ref] = commentaryText;
    }
  }
  return (
    refToRefsInBlock: refToRefsInBlock,
    refToCommentary: refToCommentary,
    allSections: allSections
  );
}

/// Loads and parses verse_commentary_mapping.txt. Section headers are lines containing one or more [c.v];
/// body runs until the next such line.
class CommentaryService {
  CommentaryService._();
  static final CommentaryService _instance = CommentaryService._();
  static CommentaryService get instance => _instance;

  static const String _assetPath = 'texts/verse_commentary_mapping.txt';

  Map<String, List<String>>? _refToRefsInBlock;
  Map<String, String>? _refToCommentary;
  List<CommentaryEntry>? _allSections;

  Future<void> _ensureLoaded() async {
    if (_refToRefsInBlock != null) return;
    try {
      final content = await rootBundle.loadString(_assetPath);
      final result = await compute(_parseCommentary, content);
      _refToRefsInBlock = result.refToRefsInBlock;
      _refToCommentary = result.refToCommentary;
      _allSections = result.allSections;
    } catch (_) {
      _refToRefsInBlock = {};
      _refToCommentary = {};
      _allSections = [];
    }
  }

  /// Returns the commentary for [ref] (e.g. "1.5"), or null if none.
  Future<CommentaryEntry?> getCommentaryForRef(String ref) async {
    await _ensureLoaded();
    final refs = _refToRefsInBlock?[ref];
    final text = _refToCommentary?[ref];
    if (refs == null || text == null || text.isEmpty) return null;
    return CommentaryEntry(refsInBlock: refs, commentaryText: text);
  }

  /// Returns a random commentary section (block of one or more verses). Null if none.
  Future<CommentaryEntry?> getRandomSection() async {
    await _ensureLoaded();
    final sections = _allSections;
    if (sections == null || sections.isEmpty) return null;
    return sections[Random().nextInt(sections.length)];
  }
}
