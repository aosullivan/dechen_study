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

  /// Resolves path list for [ref] from [_map]. Call after _ensureLoaded() or when _map non-null.
  List<Map<String, String>>? _pathForRef(String ref) {
    final verseToPath = _map?['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return null;
    var path = verseToPath[ref];
    if ((path == null || path is! List) && RegExp(r'^\d+\.\d+$').hasMatch(ref)) {
      for (final suffix in ['a', 'bcd', 'ab', 'cd']) {
        path = verseToPath['$ref$suffix'];
        if (path is List && path.isNotEmpty) break;
      }
    }
    if (path is! List) return null;
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

  /// Returns the full section hierarchy for [ref] (e.g. "1.5").
  /// For split verses (8.19ab/cd), use cd path when ref is base "8.19" (continuation).
  /// For verses like 7.1/7.2 in root text, fallback to 7.1a/7.1bcd etc. when base ref missing.
  Future<List<Map<String, String>>> getHierarchyForVerse(String ref) async {
    await _ensureLoaded();
    return _pathForRef(ref) ?? [];
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

  List<({String path, String title, int depth})>? _flatSections;

  /// Returns breadcrumb hierarchy for section path (e.g. "3.1.3" -> root to that section).
  /// Call after _ensureLoaded(). Used when user taps a section to update UI immediately.
  List<Map<String, String>> getHierarchyForSectionSync(String sectionPath) {
    if (sectionPath.isEmpty) return [];
    final flat = getFlatSectionsSync();
    final parts = sectionPath.split('.');
    final out = <Map<String, String>>[];
    var prefix = '';
    for (var i = 0; i < parts.length; i++) {
      prefix = prefix.isEmpty ? parts[i] : '$prefix.${parts[i]}';
      final idx = flat.indexWhere((s) => s.path == prefix);
      if (idx >= 0) {
        final item = flat[idx];
        out.add({'section': item.path, 'path': item.path, 'title': item.title});
      }
    }
    return out;
  }

  /// Flattened list of all sections in depth-first order. Call after _ensureLoaded().
  List<({String path, String title, int depth})> getFlatSectionsSync() {
    if (_flatSections != null) return _flatSections!;
    final sections = _map?['sections'];
    if (sections is! List) return [];
    final out = <({String path, String title, int depth})>[];
    void visit(dynamic node, int depth) {
      if (node is! Map) return;
      final path = (node['path'] ?? '').toString();
      final title = (node['title'] ?? '').toString();
      if (path.isNotEmpty && title.isNotEmpty) {
        out.add((path: path, title: title, depth: depth));
      }
      final children = node['children'];
      if (children is List) {
        for (final c in children) {
          visit(c, depth + 1);
        }
      }
    }
    for (final s in sections) {
      visit(s, 0);
    }
    _flatSections = out;
    return out;
  }

  /// For a base ref (e.g. "7.7") that splits into ab/cd in different sections,
  /// returns segments [(ref, leafSectionPath), ...] in document order.
  /// Empty if ref is not split or not found.
  List<({String ref, String sectionPath})> getSplitVerseSegmentsSync(
      String baseRef) {
    if (_map == null || !RegExp(r'^\d+\.\d+$').hasMatch(baseRef)) {
      return [];
    }
    final verseToPath = _map!['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return [];
    final abPath = verseToPath['${baseRef}ab'];
    final cdPath = verseToPath['${baseRef}cd'];
    final aPath = verseToPath['${baseRef}a'];
    final bcdPath = verseToPath['${baseRef}bcd'];
    final segments = <({String ref, String sectionPath})>[];
    String? leafSection(dynamic path) {
      if (path is! List || path.isEmpty) return null;
      final last = path.last;
      if (last is Map) {
        return (last['section'] ?? last['path'] ?? '').toString();
      }
      return null;
    }

    if (abPath != null && cdPath != null) {
      final abLeaf = leafSection(abPath);
      final cdLeaf = leafSection(cdPath);
      if (abLeaf != null && cdLeaf != null && abLeaf != cdLeaf) {
        segments.add((ref: '${baseRef}ab', sectionPath: abLeaf));
        segments.add((ref: '${baseRef}cd', sectionPath: cdLeaf));
      }
    } else if (aPath != null && bcdPath != null) {
      final aLeaf = leafSection(aPath);
      final bcdLeaf = leafSection(bcdPath);
      if (aLeaf != null && bcdLeaf != null && aLeaf != bcdLeaf) {
        segments.add((ref: '${baseRef}a', sectionPath: aLeaf));
        segments.add((ref: '${baseRef}bcd', sectionPath: bcdLeaf));
      }
    }
    return segments;
  }

  /// Synchronous getter - call after _ensureLoaded() or getHierarchyForVerse has been called.
  List<Map<String, String>> getHierarchyForVerseSync(String ref) {
    if (_map == null) return [];
    return _pathForRef(ref) ?? [];
  }
}
