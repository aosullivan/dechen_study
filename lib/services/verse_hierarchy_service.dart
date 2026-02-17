import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  static Map<String, dynamic> _decodeJson(String content) {
    return Map<String, dynamic>.from(jsonDecode(content) as Map);
  }

  Future<void> _ensureLoaded() async {
    if (_map != null) return;
    try {
      final content = await rootBundle.loadString(_assetPath);
      _map = await compute(_decodeJson, content);
    } catch (_) {
      _map = {};
    }
  }

  /// Resolves path list for [ref] from [_map]. Call after _ensureLoaded() or when _map non-null.
  /// For verses missing from the map (e.g. 6.23, 6.24), falls back to adjacent verses in same chapter.
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
    if ((path == null || path is! List) && RegExp(r'^\d+\.\d+$').hasMatch(ref)) {
      path = _pathFromAdjacentVerse(verseToPath, ref);
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

  /// When [ref] has no path, try adjacent verses (v-1, v+1, v-2, v+2, ...) until one has a path.
  dynamic _pathFromAdjacentVerse(Map verseToPath, String ref) {
    final parts = ref.split('.');
    if (parts.length != 2) return null;
    final ch = int.tryParse(parts[0]);
    final v = int.tryParse(parts[1]);
    if (ch == null || v == null || v < 1) return null;
    for (var offset = 1; offset <= 20; offset++) {
      if (v - offset >= 1) {
        final candidate = '$ch.${v - offset}';
        final p = verseToPath[candidate];
        if (p is List && p.isNotEmpty) return p;
      }
      final candidate = '$ch.${v + offset}';
      final p = verseToPath[candidate];
      if (p is List && p.isNotEmpty) return p;
    }
    return null;
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
    return getFirstVerseForSectionSync(sectionPath);
  }

  /// Sync version. Call after _ensureLoaded().
  /// Derives from verseToPath (source of truth) rather than sectionToFirstVerse,
  /// which can contain non-consecutive or parent/child inconsistencies.
  String? getFirstVerseForSectionSync(String sectionPath) {
    final refs = getVerseRefsForSectionSync(sectionPath);
    if (refs.isEmpty) return null;
    final sorted = refs.toList()..sort(_compareVerseRefs);
    return sorted.first;
  }

  /// First verse for section, preferring [preferredChapter] when the section
  /// has verses in multiple chapters (e.g. duplicate titles like "Abandoning objections").
  /// Call after _ensureLoaded().
  String? getFirstVerseForSectionInChapterSync(
      String sectionPath, int? preferredChapter) {
    final refs = getVerseRefsForSectionSync(sectionPath);
    if (refs.isEmpty) return getFirstVerseForSectionSync(sectionPath);

    if (preferredChapter != null) {
      final inChapter = refs
          .where((r) {
            final parts = r.split('.');
            if (parts.length != 2) return false;
            final ch = int.tryParse(parts[0]);
            return ch == preferredChapter;
          })
          .toList();
      if (inChapter.isNotEmpty) {
        inChapter.sort(_compareVerseRefs);
        return inChapter.first;
      }
    }
    final sorted = refs.toList()..sort(_compareVerseRefs);
    return sorted.first;
  }

  /// Compare verse refs: negative if a < b, 0 if equal, positive if a > b.
  static int compareVerseRefs(String a, String b) => _compareVerseRefs(a, b);

  /// Find the next (direction 1) or previous (direction -1) section by visible verse.
  /// Uses verse order so 8.114 -> next goes to first section with firstVerse > 8.114 (e.g. 8.115),
  /// not 8.117 (which is in a section whose first verse is 8.110).
  int findAdjacentSectionIndex(
    List<({String path, String title, int depth})> ordered,
    String currentVerseRef, {
    required int direction,
  }) {
    if (ordered.isEmpty) return -1;
    final cur = currentVerseRef;
    if (direction > 0) {
      for (var i = 0; i < ordered.length; i++) {
        final r = getFirstVerseForSectionSync(ordered[i].path);
        if (r != null && _compareVerseRefs(r, cur) > 0) return i;
      }
      return -1;
    } else {
      for (var i = ordered.length - 1; i >= 0; i--) {
        final r = getFirstVerseForSectionSync(ordered[i].path);
        if (r != null && _compareVerseRefs(r, cur) < 0) return i;
      }
      return -1;
    }
  }

  /// Leaf sections only (no children), sorted by first verse. For reader arrow-key navigation.
  /// Ensures each key down moves exactly one "lowest level" section forward.
  List<({String path, String title, int depth})> getLeafSectionsByVerseOrderSync() {
    final flat = getFlatSectionsSync();
    final pathSet = flat.map((s) => s.path).toSet();
    final leaves = flat.where((s) {
      return !pathSet.any((p) => p != s.path && p.startsWith('${s.path}.'));
    }).toList();
    final withFirst = <({String path, String title, int depth, String firstRef})>[];
    for (final s in leaves) {
      final ref = getFirstVerseForSectionSync(s.path);
      if (ref != null && ref.isNotEmpty) {
        withFirst.add((path: s.path, title: s.title, depth: s.depth, firstRef: ref));
      }
    }
    withFirst.sort((a, b) => _compareVerseRefs(a.firstRef, b.firstRef));
    return withFirst
        .map((e) => (path: e.path, title: e.title, depth: e.depth))
        .toList();
  }

  /// Sections with first verse, sorted by verse order. For arrow-key navigation.
  /// Deduplicates sections that share the same base verse (e.g. 9.1ab and 9.1cd)
  /// so we don't step through each split-verse segment.
  List<({String path, String title, int depth})> getSectionsByVerseOrderSync() {
    final flat = getFlatSectionsSync();
    final withFirst = <({String path, String title, int depth, String firstRef})>[];
    for (final s in flat) {
      final ref = getFirstVerseForSectionSync(s.path);
      if (ref != null && ref.isNotEmpty) {
        withFirst.add((path: s.path, title: s.title, depth: s.depth, firstRef: ref));
      }
    }
    withFirst.sort((a, b) => _compareVerseRefs(a.firstRef, b.firstRef));
    // Keep one section per (chapter, verse) - skip 9.1cd when we already have 9.1ab
    final deduped = <({String path, String title, int depth})>[];
    (int, int)? prevBase;
    for (final e in withFirst) {
      final base = _baseVerse(e.firstRef);
      if (prevBase != null && base.$1 == prevBase.$1 && base.$2 == prevBase.$2) {
        continue;
      }
      prevBase = base;
      deduped.add((path: e.path, title: e.title, depth: e.depth));
    }
    return deduped;
  }

  static (int, int) _baseVerse(String ref) => baseVerseFromRef(ref);

  /// Public for callers that need to map a section to its verse-order position.
  static (int, int) baseVerseFromRef(String ref) {
    final m = RegExp(r'^(\d+)\.(\d+)').firstMatch(ref);
    if (m == null) return (0, 0);
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  static int _compareVerseRefs(String a, String b) {
    final am = RegExp(r'^(\d+)\.(\d+)').firstMatch(a);
    final bm = RegExp(r'^(\d+)\.(\d+)').firstMatch(b);
    if (am == null || bm == null) return a.compareTo(b);
    final ac = int.parse(am.group(1)!);
    final av = int.parse(am.group(2)!);
    final bc = int.parse(bm.group(1)!);
    final bv = int.parse(bm.group(2)!);
    if (ac != bc) return ac.compareTo(bc);
    return av.compareTo(bv);
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
