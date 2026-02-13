import 'dart:convert';

import 'package:flutter/services.dart';

import 'bcv_verse_service.dart';

/// Loads verse hierarchy mapping and provides section path for each verse.
/// Hierarchy comes from overviews-pages (EOS).txt (definitive source).
class VerseHierarchyService {
  VerseHierarchyService._();
  static final VerseHierarchyService _instance = VerseHierarchyService._();
  static VerseHierarchyService get instance => _instance;

  static const String _assetPath = 'texts/verse_hierarchy_map.json';

  Map<String, dynamic>? _map;

  Future<void> _ensureLoaded() async {
    if (_map != null) return;
    try {
      final content = await rootBundle.loadString(_assetPath);
      _map = Map<String, dynamic>.from(jsonDecode(content) as Map);
    } catch (_) {
      _map = {};
    }
  }

  /// Returns the full section hierarchy for [ref] (e.g. "1.5").
  /// Each item has 'section' (section number) and 'title'. Empty list if not found.
  Future<List<Map<String, String>>> getHierarchyForVerse(String ref) async {
    await _ensureLoaded();
    final verseToPath = _map?['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return [];
    final path = verseToPath[ref];
    if (path is! List) return [];
    return path.map((e) {
      if (e is Map) {
        return <String, String>{
          'section': (e['section'] ?? e['path'] ?? '').toString(),
          'title': (e['title'] ?? '').toString(),
        };
      }
      return <String, String>{'section': '', 'title': e.toString()};
    }).toList();
  }

  /// Returns the hierarchy for the verse at [index]. Uses BcvVerseService to resolve ref.
  Future<List<Map<String, String>>> getHierarchyForVerseIndex(int index) async {
    final ref = BcvVerseService.instance.getVerseRef(index);
    if (ref == null) return [];
    return getHierarchyForVerse(ref);
  }

  /// Synchronous getter - call after _ensureLoaded() or getHierarchyForVerse has been called.
  List<Map<String, String>> getHierarchyForVerseSync(String ref) {
    if (_map == null) return [];
    final verseToPath = _map!['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return [];
    final path = verseToPath[ref];
    if (path is! List) return [];
    return path.map((e) {
      if (e is Map) {
        return <String, String>{
          'section': (e['section'] ?? e['path'] ?? '').toString(),
          'title': (e['title'] ?? '').toString(),
        };
      }
      return <String, String>{'section': '', 'title': e.toString()};
    }).toList();
  }
}
