import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/study_text_config.dart';
import '../utils/verse_ref_formatter.dart';
import 'verse_service.dart';

/// Params to open the reader at a section (e.g. "Full text" from overview or daily).
/// Reused so overview and daily use the same logic and jump to the correct verse.
class ReaderOpenParams {
  const ReaderOpenParams({
    required this.scrollToVerseIndex,
    required this.highlightSectionIndices,
    this.initialSegmentRef,
  });
  final int scrollToVerseIndex;
  final Set<int> highlightSectionIndices;
  final String? initialSegmentRef;
}

/// Holds parsed hierarchy data from the background isolate.
class _ParsedHierarchy {
  _ParsedHierarchy({
    required this.map,
    required this.sectionToRefs,
    required this.sectionOwnRefs,
  });
  final Map<String, dynamic> map;
  final Map<String, Set<String>> sectionToRefs;
  final Map<String, Set<String>> sectionOwnRefs;
}

/// Walks the sections tree and adds each node's [verses] entries to [out].
/// This supplements [verseToPath] which only stores base refs pointing to
/// parent sections — the tree's [verses] arrays carry the segment-level refs
/// (e.g. "9.27cd") and point directly to the leaf section that owns them.
void _walkSectionsForRefs(dynamic node, Map<String, Set<String>> out) {
  if (node is! Map) return;
  final path = (node['path'] ?? '').toString();
  final verses = node['verses'];
  if (path.isNotEmpty && verses is List) {
    for (final v in verses) {
      final ref = (v ?? '').toString();
      if (ref.isNotEmpty) (out[path] ??= {}).add(ref);
    }
  }
  final children = node['children'];
  if (children is List) {
    for (final c in children) {
      _walkSectionsForRefs(c, out);
    }
  }
}

/// Loads verse hierarchy mapping and provides section path for each verse.
/// Data is keyed by textId; paths come from [StudyTextConfig].
class VerseHierarchyService {
  VerseHierarchyService._();
  static final VerseHierarchyService _instance = VerseHierarchyService._();
  static VerseHierarchyService get instance => _instance;

  final Map<String, _HierarchyState> _cache = {};

  String? _assetPathFor(String textId) {
    return getStudyText(textId)?.hierarchyPath;
  }

  /// Pre-warm: start loading and parsing for [textId].
  Future<void> preload(String textId) => _ensureLoaded(textId);

  Future<void> _ensureLoaded(String textId) async {
    if (_cache.containsKey(textId)) return;
    final path = _assetPathFor(textId);
    if (path == null || path.isEmpty) return;
    try {
      final content = await rootBundle.loadString(path);
      final result = await compute(_decodeAndIndex, content);
      _cache[textId] = _HierarchyState(
        map: result.map,
        sectionToRefsIndex: result.sectionToRefs,
        sectionOwnRefsIndex: result.sectionOwnRefs,
      );
    } catch (_) {
      _cache[textId] = _HierarchyState(
        map: {},
        sectionToRefsIndex: {},
        sectionOwnRefsIndex: {},
      );
    }
  }

  _HierarchyState? _get(String textId) => _cache[textId];

  /// Resolves path list for [ref]. Call after _ensureLoaded() or when state is non-null.
  List<Map<String, String>>? _pathForRef(_HierarchyState s, String ref) {
    final verseToPath = s.map['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return null;
    var path = verseToPath[ref];
    if (path == null || path is! List) {
      // Segment refs like "1.2abc"/"1.4ab" should resolve through their base.
      final baseRef = _baseRefFromAny(ref);
      if (baseRef != null && baseRef != ref) {
        path = verseToPath[baseRef];
      }
    }
    if ((path == null || path is! List) &&
        VerseService.baseVerseRefPattern.hasMatch(ref)) {
      for (final suffix in ['ab', 'cd', 'a', 'bcd']) {
        path = verseToPath['$ref$suffix'];
        if (path is List && path.isNotEmpty) break;
      }
    }
    if ((path == null || path is! List) &&
        VerseService.baseVerseRefPattern.hasMatch(ref)) {
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

  static String? _baseRefFromAny(String ref) {
    final m = RegExp(r'^(\d+\.\d+)', caseSensitive: false).firstMatch(ref);
    return m?.group(1);
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

  /// Returns the full section hierarchy for [ref] (e.g. "1.5") for [textId].
  Future<List<Map<String, String>>> getHierarchyForVerse(
      String textId, String ref) async {
    await _ensureLoaded(textId);
    final s = _get(textId);
    if (s == null) return [];
    return _pathForRef(s, ref) ?? [];
  }

  /// Returns the first verse ref for a section path (e.g. "3.1.3"), or null.
  Future<String?> getFirstVerseForSection(
      String textId, String sectionPath) async {
    await _ensureLoaded(textId);
    return getFirstVerseForSectionSync(textId, sectionPath);
  }

  /// Sync version. Call after _ensureLoaded().
  String? getFirstVerseForSectionSync(String textId, String sectionPath) {
    final s = _get(textId);
    if (s == null) return null;
    final leafFirst = s.cachedLeafFirstRefs?[sectionPath];
    if (leafFirst != null && leafFirst.isNotEmpty) return leafFirst;
    final ownRefs = getOwnVerseRefsForSectionSync(textId, sectionPath);
    if (ownRefs.isNotEmpty) {
      final ownSorted = ownRefs.toList()..sort(_compareVerseRefsFull);
      return ownSorted.first;
    }
    final refs = getVerseRefsForSectionSync(textId, sectionPath);
    if (refs.isEmpty) return null;
    final sorted = refs.toList()..sort(_compareVerseRefsFull);
    return sorted.first;
  }

  /// First verse for section, preferring [preferredChapter] when the section
  /// has verses in multiple chapters.
  String? getFirstVerseForSectionInChapterSync(
      String textId, String sectionPath, int? preferredChapter) {
    final s = _get(textId);
    if (s == null) return null;
    final ownRefs = getOwnVerseRefsForSectionSync(textId, sectionPath);
    final refs = ownRefs.isNotEmpty
        ? ownRefs
        : getVerseRefsForSectionSync(textId, sectionPath);
    if (refs.isEmpty) return getFirstVerseForSectionSync(textId, sectionPath);

    if (preferredChapter != null) {
      final inChapter = refs.where((r) {
        final parts = r.split('.');
        if (parts.length != 2) return false;
        final ch = int.tryParse(parts[0]);
        return ch == preferredChapter;
      }).toList();
      if (inChapter.isNotEmpty) {
        inChapter.sort(_compareVerseRefsFull);
        return inChapter.first;
      }
    }
    final sorted = refs.toList()..sort(_compareVerseRefsFull);
    return sorted.first;
  }

  /// Compare verse refs: negative if a < b, 0 if equal, positive if a > b.
  static int compareVerseRefs(String a, String b) => _compareVerseRefs(a, b);

  /// Find the next (direction 1) or previous (direction -1) section by visible verse.
  int findAdjacentSectionIndex(
    String textId,
    List<({String path, String title, int depth})> ordered,
    String currentVerseRef, {
    required int direction,
    bool useFullRefOrder = false,
  }) {
    if (ordered.isEmpty) return -1;
    final cur = currentVerseRef;
    final compare = useFullRefOrder ? _compareVerseRefsFull : _compareVerseRefs;
    if (direction > 0) {
      for (var i = 0; i < ordered.length; i++) {
        final r = getFirstVerseForSectionSync(textId, ordered[i].path);
        if (r != null && compare(r, cur) > 0) return i;
      }
      return -1;
    } else {
      for (var i = ordered.length - 1; i >= 0; i--) {
        final r = getFirstVerseForSectionSync(textId, ordered[i].path);
        if (r != null && compare(r, cur) < 0) return i;
      }
      return -1;
    }
  }

  /// Navigable sections sorted by first verse for reader arrow-key navigation.
  /// Result is cached after first computation.
  List<({String path, String title, int depth})>
      getLeafSectionsByVerseOrderSync(String textId) {
    final s = _get(textId);
    if (s == null) return [];
    if (s.cachedLeafSections != null) return s.cachedLeafSections!;
    final sections = s.map['sections'];
    if (sections is! List) return [];
    final withFirst =
        <({String path, String title, int depth, String firstRef})>[];

    Set<String> visit(dynamic node, int depth) {
      if (node is! Map) return {};
      final path = (node['path'] ?? '').toString();
      final title = (node['title'] ?? '').toString();
      final children = node['children'];
      final childRefs = <String>{};
      final hasChildren = children is List && children.isNotEmpty;
      if (children is List) {
        for (final c in children) {
          childRefs.addAll(visit(c, depth + 1));
        }
      }

      final sectionRefs =
          Set<String>.from(s.sectionToRefsIndex[path] ?? const <String>{});
      final subtreeRefs = <String>{...sectionRefs, ...childRefs};
      final ownRefs =
          Set<String>.from(s.sectionOwnRefsIndex[path] ?? const <String>{});
      final ownExclusiveRefs =
          ownRefs.where((r) => !childRefs.contains(r)).toSet();
      final navigableRefs = hasChildren
          ? ownExclusiveRefs
          : (ownRefs.isNotEmpty ? ownRefs : sectionRefs);

      if (path.isNotEmpty && title.isNotEmpty && navigableRefs.isNotEmpty) {
        final sorted = navigableRefs.toList()..sort(_compareVerseRefsFull);
        withFirst.add(
          (
            path: path,
            title: title,
            depth: depth,
            firstRef: sorted.first,
          ),
        );
      }

      return subtreeRefs;
    }

    for (final section in sections) {
      visit(section, 0);
    }
    withFirst.sort((a, b) => _compareVerseRefsFull(a.firstRef, b.firstRef));
    s.cachedLeafFirstRefs = {for (final e in withFirst) e.path: e.firstRef};
    s.cachedLeafSections = withFirst
        .map((e) => (path: e.path, title: e.title, depth: e.depth))
        .toList();
    return s.cachedLeafSections!;
  }

  /// Sections with first verse, sorted by verse order. For arrow-key navigation.
  /// Result is cached after first computation.
  List<({String path, String title, int depth})> getSectionsByVerseOrderSync(
      String textId) {
    final s = _get(textId);
    if (s == null) return [];
    if (s.cachedSectionsByVerseOrder != null) {
      return s.cachedSectionsByVerseOrder!;
    }
    final flat = getFlatSectionsSync(textId);
    final withFirst =
        <({String path, String title, int depth, String firstRef})>[];
    for (final section in flat) {
      final ref = getFirstVerseForSectionSync(textId, section.path);
      if (ref != null && ref.isNotEmpty) {
        withFirst.add((
          path: section.path,
          title: section.title,
          depth: section.depth,
          firstRef: ref
        ));
      }
    }
    withFirst.sort((a, b) => _compareVerseRefsFull(a.firstRef, b.firstRef));
    final deduped = <({String path, String title, int depth})>[];
    (int, int)? prevBase;
    for (final e in withFirst) {
      final base = _baseVerse(e.firstRef);
      if (prevBase != null &&
          base.$1 == prevBase.$1 &&
          base.$2 == prevBase.$2) {
        continue;
      }
      prevBase = base;
      deduped.add((path: e.path, title: e.title, depth: e.depth));
    }
    s.cachedSectionsByVerseOrder = deduped;
    return s.cachedSectionsByVerseOrder!;
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

  /// Like [_compareVerseRefs] but breaks ties by full ref (8.136ab < 8.136cd).
  /// Use for leaf-section order and for "next section" when multiple sections share a base verse.
  static int _compareVerseRefsFull(String a, String b) {
    final c = _compareVerseRefs(a, b);
    if (c != 0) return c;
    return a.compareTo(b);
  }

  /// Returns the hierarchy for the verse at [index] for [textId].
  Future<List<Map<String, String>>> getHierarchyForVerseIndex(
      String textId, int index) async {
    final ref = VerseService.instance.getVerseRef(textId, index);
    if (ref == null) return [];
    return getHierarchyForVerse(textId, ref);
  }

  /// Returns verse refs whose path contains [sectionPath] (section + descendants).
  Set<String> getVerseRefsForSectionSync(String textId, String sectionPath) {
    final s = _get(textId);
    if (s == null || sectionPath.isEmpty) return {};
    return s.sectionToRefsIndex[sectionPath] ?? {};
  }

  /// Returns only the refs directly owned by [sectionPath].
  Set<String> getOwnVerseRefsForSectionSync(String textId, String sectionPath) {
    final s = _get(textId);
    if (s == null || sectionPath.isEmpty) return {};
    return s.sectionOwnRefsIndex[sectionPath] ?? {};
  }

  /// Returns refs from the section tree only: [sectionPath] own refs plus all descendants' own refs.
  Set<String> getTreeVerseRefsForSectionSync(
      String textId, String sectionPath) {
    final s = _get(textId);
    if (s == null || sectionPath.isEmpty) return {};
    final ownIndex = s.sectionOwnRefsIndex;
    if (ownIndex.isEmpty) return {};

    final out = <String>{};
    final prefix = '$sectionPath.';
    for (final e in ownIndex.entries) {
      final path = e.key;
      if (path == sectionPath || path.startsWith(prefix)) {
        out.addAll(e.value);
      }
    }
    return out;
  }

  /// Returns params to open BcvReadScreen at the first verse of [sectionPath] for [textId].
  ReaderOpenParams? getReaderParamsForSectionSync(
      String textId, String sectionPath) {
    if (sectionPath.isEmpty) return null;
    final ownRefs = getOwnVerseRefsForSectionSync(textId, sectionPath);
    final treeRefs = getTreeVerseRefsForSectionSync(textId, sectionPath);
    final refs = (ownRefs.isNotEmpty
            ? ownRefs
            : treeRefs.isNotEmpty
                ? treeRefs
                : getVerseRefsForSectionSync(textId, sectionPath))
        .toList()
      ..sort(_compareVerseRefsFull);

    final verseService = VerseService.instance;
    final seen = <String>{};
    final indices = <int>[];
    final refForIndex = <int, String>{};
    for (final ref in refs) {
      final idx = verseService.getIndexForRefWithFallback(textId, ref);
      if (idx == null) continue;
      final base = _baseRefFromReader(ref);
      if (!seen.add('r:$base')) continue;
      indices.add(idx);
      if (!refForIndex.containsKey(idx) ||
          VerseService.segmentSuffixPattern.hasMatch(ref)) {
        refForIndex[idx] = ref;
      }
    }
    if (indices.isEmpty) return null;
    indices.sort();
    final firstIndex = indices.first;
    return ReaderOpenParams(
      scrollToVerseIndex: firstIndex,
      highlightSectionIndices: indices.toSet(),
      initialSegmentRef: refForIndex[firstIndex],
    );
  }

  static String _baseRefFromReader(String ref) {
    final m = RegExp(r'^(\d+\.\d+)', caseSensitive: false).firstMatch(ref);
    return m?.group(1) ?? ref;
  }

  /// Pre-computed section path -> verse range string. Call after _ensureLoaded().
  Map<String, String> getSectionVerseRangeMapSync(String textId) {
    final s = _get(textId);
    if (s == null) return {};
    if (s.sectionToVerseRange != null) return s.sectionToVerseRange!;
    final flat = getFlatSectionsSync(textId);
    final out = <String, String>{};
    for (final section in flat) {
      final path = section.path;
      final ownRefs = getOwnVerseRefsForSectionSync(textId, path);
      final treeRefs = getTreeVerseRefsForSectionSync(textId, path);
      final refs = (ownRefs.isNotEmpty
              ? ownRefs
              : treeRefs.isNotEmpty
                  ? treeRefs
                  : getVerseRefsForSectionSync(textId, path))
          .toList()
        ..sort(_compareVerseRefsFull);
      if (refs.isEmpty) continue;
      out[path] = _formatVerseRange(textId, refs);
    }
    s.sectionToVerseRange = out;
    return s.sectionToVerseRange!;
  }

  /// Format sorted refs as "v1.1ab" or "v1.2-1.3", "v4.2-v4.3".
  static String _formatVerseRange(String textId, List<String> refs) =>
      formatVerseRangeForDisplay(textId, refs);

  /// Returns breadcrumb hierarchy for section path (e.g. "3.1.3" -> root to that section).
  /// Call after _ensureLoaded(). Used when user taps a section to update UI immediately.
  List<Map<String, String>> getHierarchyForSectionSync(
      String textId, String sectionPath) {
    if (sectionPath.isEmpty) return [];
    final flat = getFlatSectionsSync(textId);
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
  List<({String path, String title, int depth})> getFlatSectionsSync(
      String textId) {
    final s = _get(textId);
    if (s == null) return [];
    if (s.flatSections != null) return s.flatSections!;
    final sections = s.map['sections'];
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

    for (final section in sections) {
      visit(section, 0);
    }
    s.flatSections = out;
    return s.flatSections!;
  }

  /// For a base ref (e.g. "7.7") that splits into ab/cd in different sections,
  /// returns segments [(ref, leafSectionPath), ...] in document order.
  List<({String ref, String sectionPath})> getSplitVerseSegmentsSync(
      String textId, String baseRef) {
    final s = _get(textId);
    if (s == null || !VerseService.baseVerseRefPattern.hasMatch(baseRef)) {
      return [];
    }
    final verseToPath = s.map['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return [];

    final ownSplit =
        _collectSplitSegmentsFromIndex(s.sectionOwnRefsIndex, baseRef);
    if (ownSplit.isNotEmpty) return ownSplit;
    for (final refs in s.sectionOwnRefsIndex.values) {
      if (refs.contains(baseRef)) return [];
    }

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
    if (segments.isNotEmpty) return segments;

    return _collectSplitSegmentsFromIndex(s.sectionToRefsIndex, baseRef);
  }

  List<({String ref, String sectionPath})> _collectSplitSegmentsFromIndex(
    Map<String, Set<String>>? index,
    String baseRef,
  ) {
    if (index == null || index.isEmpty) return [];
    final byRef = <String, String>{};
    final pattern =
        RegExp('^${RegExp.escape(baseRef)}([a-d]+)\$', caseSensitive: false);
    for (final entry in index.entries) {
      final sectionPath = entry.key;
      if (sectionPath.isEmpty) continue;
      for (final ref in entry.value) {
        final m = pattern.firstMatch(ref);
        if (m == null) continue;
        // Accept only contiguous suffix ranges we can map to line ranges.
        if (VerseService.lineRangeForSegmentRef(ref, 4) == null) continue;
        byRef.putIfAbsent(ref, () => sectionPath);
      }
    }
    if (byRef.length < 2) return [];
    final distinctSections = byRef.values.toSet();
    if (distinctSections.length < 2) return [];

    final out =
        byRef.entries.map((e) => (ref: e.key, sectionPath: e.value)).toList();
    out.sort((a, b) {
      final ra = VerseService.lineRangeForSegmentRef(a.ref, 4);
      final rb = VerseService.lineRangeForSegmentRef(b.ref, 4);
      if (ra != null && rb != null) {
        final cStart = ra[0].compareTo(rb[0]);
        if (cStart != 0) return cStart;
        final cEnd = ra[1].compareTo(rb[1]);
        if (cEnd != 0) return cEnd;
      }
      return a.ref.compareTo(b.ref);
    });
    return out;
  }

  /// Synchronous getter - call after _ensureLoaded() or getHierarchyForVerse has been called.
  List<Map<String, String>> getHierarchyForVerseSync(
      String textId, String ref) {
    final s = _get(textId);
    if (s == null) return [];
    return _pathForRef(s, ref) ?? [];
  }
}

/// Per-textId hierarchy state (map + derived indexes and caches).
class _HierarchyState {
  _HierarchyState({
    required this.map,
    required this.sectionToRefsIndex,
    required this.sectionOwnRefsIndex,
  });
  final Map<String, dynamic> map;
  final Map<String, Set<String>> sectionToRefsIndex;
  final Map<String, Set<String>> sectionOwnRefsIndex;

  List<({String path, String title, int depth})>? flatSections;
  List<({String path, String title, int depth})>? cachedLeafSections;
  Map<String, String>? cachedLeafFirstRefs;
  List<({String path, String title, int depth})>? cachedSectionsByVerseOrder;
  Map<String, String>? sectionToVerseRange;
}

/// Result from background isolate: decoded map + pre-built reverse index.
_ParsedHierarchy _decodeAndIndex(String content) {
  final map = Map<String, dynamic>.from(jsonDecode(content) as Map);
  final sectionToRefs = <String, Set<String>>{};
  final sectionOwnRefs = <String, Set<String>>{};
  final verseToPath = map['verseToPath'];
  if (verseToPath is Map) {
    for (final e in verseToPath.entries) {
      final path = e.value;
      if (path is! List) continue;
      final ref = e.key.toString();
      for (final item in path) {
        if (item is Map) {
          final s = (item['section'] ?? item['path'] ?? '').toString();
          if (s.isNotEmpty) {
            (sectionToRefs[s] ??= {}).add(ref);
          }
        }
      }
    }
  }
  final sections = map['sections'];
  if (sections is List) {
    for (final s in sections) {
      _walkSectionsForRefs(s, sectionOwnRefs);
    }
    for (final e in sectionOwnRefs.entries) {
      (sectionToRefs[e.key] ??= {}).addAll(e.value);
    }
  }
  return _ParsedHierarchy(
    map: map,
    sectionToRefs: sectionToRefs,
    sectionOwnRefs: sectionOwnRefs,
  );
}
