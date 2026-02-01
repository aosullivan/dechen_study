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

/// Loads and parses commentary.txt. Section headers are lines containing one or more [c.v];
/// body runs until the next such line.
class CommentaryService {
  CommentaryService._();
  static final CommentaryService _instance = CommentaryService._();
  static CommentaryService get instance => _instance;

  static const String _assetPath = 'texts/verse_commentary_mapping.txt';
  /// Matches [c.v] and captures c.v as group 1 (with dot).
  static final RegExp _refInBrackets = RegExp(r'\[(\d+\.\d+)\]');

  Map<String, List<String>>? _refToRefsInBlock;
  Map<String, String>? _refToCommentary;

  Future<void> _ensureLoaded() async {
    if (_refToRefsInBlock != null) return;
    try {
      final content = await rootBundle.loadString(_assetPath);
      _parse(content);
    } catch (_) {
      _refToRefsInBlock = {};
      _refToCommentary = {};
    }
  }

  void _parse(String content) {
    final refToRefsInBlock = <String, List<String>>{};
    final refToCommentary = <String, String>{};
    final lines = content.split('\n');
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final refs = _refInBrackets.allMatches(line).map((m) => m.group(1)!).toList();
      if (refs.isEmpty) {
        i++;
        continue;
      }
      final refsDeduped = refs.toSet().toList();
      final bodyLines = <String>[];
      i++;
      while (i < lines.length) {
        final next = lines[i];
        if (_refInBrackets.hasMatch(next)) break;
        bodyLines.add(next);
        i++;
      }
      final commentaryText = bodyLines.join('\n').trim();
      for (final ref in refsDeduped) {
        refToRefsInBlock[ref] = refsDeduped;
        refToCommentary[ref] = commentaryText;
      }
    }
    _refToRefsInBlock = refToRefsInBlock;
    _refToCommentary = refToCommentary;
  }

  /// Returns the commentary for [ref] (e.g. "1.5"), or null if none.
  Future<CommentaryEntry?> getCommentaryForRef(String ref) async {
    await _ensureLoaded();
    final refs = _refToRefsInBlock?[ref];
    final text = _refToCommentary?[ref];
    if (refs == null || text == null || text.isEmpty) return null;
    return CommentaryEntry(refsInBlock: refs, commentaryText: text);
  }
}
