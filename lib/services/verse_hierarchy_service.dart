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
  /// For split verses (8.19ab/cd), use cd path when ref is base "8.19" (continuation).
  Future<List<Map<String, String>>> getHierarchyForVerse(String ref) async {
    await _ensureLoaded();
    final verseToPath = _map?['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return [];
    var path = verseToPath[ref];
    if ((path == null || path is! List) && RegExp(r'^\d+\.\d+$').hasMatch(ref)) {
      path = verseToPath['${ref}cd'] ?? verseToPath['${ref}ab'];
    }
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

  /// Returns the first verse ref for a section path (e.g. "3.1.3"), or null.
  Future<String?> getFirstVerseForSection(String sectionPath) async {
    await _ensureLoaded();
    final map = _map?['sectionToFirstVerse'];
    if (map == null || map is! Map) return null;
    final ref = map[sectionPath];
    return ref?.toString();
  }

  /// Returns the hierarchy for the verse at [index]. Uses BcvVerseService to resolve ref.
  Future<List<Map<String, String>>> getHierarchyForVerseIndex(int index) async {
    final ref = BcvVerseService.instance.getVerseRef(index);
    if (ref == null) return [];
    return getHierarchyForVerse(ref);
  }

  /// Returns verse refs whose path contains [sectionPath] (section + descendants).
  /// Call after _ensureLoaded() or any getter has been called.
  Set<String> getVerseRefsForSectionSync(String sectionPath) {
    if (_map == null || sectionPath.isEmpty) return {};
    final verseToPath = _map!['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return {};
    final refs = <String>{};
    for (final e in verseToPath.entries) {
      final path = e.value;
      if (path is! List) continue;
      for (final item in path) {
        if (item is Map) {
          final s = (item['section'] ?? item['path'] ?? '').toString();
          if (s == sectionPath) {
            refs.add(e.key.toString());
            break;
          }
        }
      }
    }
    return refs;
  }

  /// Synchronous getter - call after _ensureLoaded() or getHierarchyForVerse has been called.
  List<Map<String, String>> getHierarchyForVerseSync(String ref) {
    if (_map == null) return [];
    final verseToPath = _map!['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return [];
    var path = verseToPath[ref];
    if ((path == null || path is! List) && RegExp(r'^\d+\.\d+$').hasMatch(ref)) {
      path = verseToPath['${ref}cd'] ?? verseToPath['${ref}ab'];
    }
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
