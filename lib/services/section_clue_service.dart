import 'dart:convert';
import 'package:flutter/services.dart';

import '../config/study_text_config.dart';

/// Loads section_clues.json per text and provides clue lookup by verse ref.
class SectionClueService {
  SectionClueService._();
  static final SectionClueService _instance = SectionClueService._();
  static SectionClueService get instance => _instance;

  final Map<String, Map<String, String>> _cache = {};

  String? _assetPathFor(String textId) {
    return getStudyText(textId)?.sectionCluesPath;
  }

  Future<void> _ensureLoaded(String textId) async {
    if (_cache.containsKey(textId)) return;
    final path = _assetPathFor(textId);
    if (path == null || path.isEmpty) return;
    try {
      final content = await rootBundle.loadString(path);
      final decoded = json.decode(content) as Map<String, dynamic>;
      _cache[textId] = decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      _cache[textId] = {};
    }
  }

  /// Returns the clue for the given verse ref (e.g. "1.5") for [textId], or null if none.
  Future<String?> getClueForRef(String textId, String ref) async {
    await _ensureLoaded(textId);
    return _cache[textId]?[ref];
  }
}
