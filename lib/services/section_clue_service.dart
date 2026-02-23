import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads section_clues.json and provides clue lookup by verse ref.
class SectionClueService {
  SectionClueService._();
  static final SectionClueService _instance = SectionClueService._();
  static SectionClueService get instance => _instance;

  static const String _assetPath = 'texts/section_clues.json';

  Map<String, String>? _clues;

  Future<void> _ensureLoaded() async {
    if (_clues != null) return;
    try {
      final content = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(content) as Map<String, dynamic>;
      _clues = decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      _clues = {};
    }
  }

  /// Returns the clue for the given verse ref (e.g. "1.5"), or null if none.
  Future<String?> getClueForRef(String ref) async {
    await _ensureLoaded();
    return _clues?[ref];
  }
}
