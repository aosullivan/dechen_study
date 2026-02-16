import 'dart:math';
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

/// Loads and parses verse_commentary_mapping.txt. Section headers are lines containing one or more [c.v];
/// body runs until the next such line.
class CommentaryService {
  CommentaryService._();
  static final CommentaryService _instance = CommentaryService._();
  static CommentaryService get instance => _instance;

  static const String _assetPath = 'texts/verse_commentary_mapping.txt';
  /// Matches [c.v] and captures c.v as group 1 (with dot).
  static final RegExp _refInBrackets = RegExp(r'\[(\d+\.\d+)\]');

  /// Sort verse refs by chapter then verse (e.g. 6.27 before 6.31).
  static int _compareRefs(String a, String b) {
    final ap = a.split('.');
    final bp = b.split('.');
    if (ap.length != 2 || bp.length != 2) return a.compareTo(b);
    final ac = int.tryParse(ap[0]) ?? 0;
    final av = int.tryParse(ap[1]) ?? 0;
    final bc = int.tryParse(bp[0]) ?? 0;
    final bv = int.tryParse(bp[1]) ?? 0;
    if (ac != bc) return ac.compareTo(bc);
    return av.compareTo(bv);
  }

  Map<String, List<String>>? _refToRefsInBlock;
  Map<String, String>? _refToCommentary;
  List<CommentaryEntry>? _allSections;

  Future<void> _ensureLoaded() async {
    if (_refToRefsInBlock != null) return;
    try {
      final content = await rootBundle.loadString(_assetPath);
      _parse(content);
    } catch (_) {
      _refToRefsInBlock = {};
      _refToCommentary = {};
      _allSections = [];
    }
  }

  void _parse(String content) {
    final refToRefsInBlock = <String, List<String>>{};
    final refToCommentary = <String, String>{};
    final allSections = <CommentaryEntry>[];
    final lines = content.split('\n');
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final refs = _refInBrackets.allMatches(line).map((m) => m.group(1)!).toList();
      if (refs.isEmpty) {
        i++;
        continue;
      }
      final refsDeduped = refs.toSet().toList()
        ..sort(_compareRefs);
      final bodyLines = <String>[];
      i++;
      while (i < lines.length) {
        final next = lines[i];
        if (_refInBrackets.hasMatch(next)) break;
        bodyLines.add(next);
        i++;
      }
      final commentaryText = bodyLines.join('\n').trim();
      final entry = CommentaryEntry(refsInBlock: refsDeduped, commentaryText: commentaryText);
      allSections.add(entry);
      for (final ref in refsDeduped) {
        refToRefsInBlock[ref] = refsDeduped;
        refToCommentary[ref] = commentaryText;
      }
    }
    _refToRefsInBlock = refToRefsInBlock;
    _refToCommentary = refToCommentary;
    _allSections = allSections;
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
