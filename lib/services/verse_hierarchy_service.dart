import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bcv_verse_service.dart';

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
/// Hierarchy source of truth is texts/verse_hierarchy_map.json.
class VerseHierarchyService {
  VerseHierarchyService._();
  static final VerseHierarchyService _instance = VerseHierarchyService._();
  static VerseHierarchyService get instance => _instance;

  static const String _assetPath = 'texts/verse_hierarchy_map.json';

  Map<String, dynamic>? _map;

  /// Result from background isolate: decoded map + pre-built reverse index.
  static _ParsedHierarchy _decodeAndIndex(String content) {
    final map = Map<String, dynamic>.from(jsonDecode(content) as Map);
    // Build reverse index (section path -> verse refs) in the isolate to avoid main-thread work.
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
    // Also index verses from sections.verses arrays.  verseToPath only carries
    // base refs pointing to parent sections; the tree's verses arrays hold the
    // segment-level refs (e.g. "9.27cd") that belong to each leaf section.
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

  /// Pre-warm: start loading and parsing so it's ready when the read screen opens.
  Future<void> preload() => _ensureLoaded();

  Future<void> _ensureLoaded() async {
    if (_map != null) return;
    try {
      final content = await rootBundle.loadString(_assetPath);
      final result = await compute(_decodeAndIndex, content);
      _map = result.map;
      _sectionToRefsIndex = result.sectionToRefs;
      _sectionOwnRefsIndex = result.sectionOwnRefs;
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
    if ((path == null || path is! List) &&
        BcvVerseService.baseVerseRefPattern.hasMatch(ref)) {
      for (final suffix in ['ab', 'cd', 'a', 'bcd']) {
        path = verseToPath['$ref$suffix'];
        if (path is List && path.isNotEmpty) break;
      }
    }
    if ((path == null || path is! List) &&
        BcvVerseService.baseVerseRefPattern.hasMatch(ref)) {
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
    final leafFirst = _cachedLeafFirstRefs?[sectionPath];
    if (leafFirst != null && leafFirst.isNotEmpty) return leafFirst;
    final ownRefs = getOwnVerseRefsForSectionSync(sectionPath);
    if (ownRefs.isNotEmpty) {
      final ownSorted = ownRefs.toList()..sort(_compareVerseRefsFull);
      return ownSorted.first;
    }
    final refs = getVerseRefsForSectionSync(sectionPath);
    if (refs.isEmpty) return null;
    // Use full-ref ordering so split refs are deterministic (e.g. 7.2a before 7.2bcd).
    final sorted = refs.toList()..sort(_compareVerseRefsFull);
    return sorted.first;
  }

  /// First verse for section, preferring [preferredChapter] when the section
  /// has verses in multiple chapters (e.g. duplicate titles like "Abandoning objections").
  /// Call after _ensureLoaded().
  String? getFirstVerseForSectionInChapterSync(
      String sectionPath, int? preferredChapter) {
    final ownRefs = getOwnVerseRefsForSectionSync(sectionPath);
    final refs =
        ownRefs.isNotEmpty ? ownRefs : getVerseRefsForSectionSync(sectionPath);
    if (refs.isEmpty) return getFirstVerseForSectionSync(sectionPath);

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
  /// Uses verse order so 8.114 -> next goes to first section with firstVerse > 8.114 (e.g. 8.115),
  /// not 8.117 (which is in a section whose first verse is 8.110).
  /// When [useFullRefOrder] is true (e.g. leaf list with split verses), 8.136ab -> next is 8.136cd.
  /// When false (deduplicated list), 9.1 -> next is 9.2 (one section per base verse).
  int findAdjacentSectionIndex(
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
        final r = getFirstVerseForSectionSync(ordered[i].path);
        if (r != null && compare(r, cur) > 0) return i;
      }
      return -1;
    } else {
      for (var i = ordered.length - 1; i >= 0; i--) {
        final r = getFirstVerseForSectionSync(ordered[i].path);
        if (r != null && compare(r, cur) < 0) return i;
      }
      return -1;
    }
  }

  /// Navigable sections sorted by first verse for reader arrow-key navigation.
  ///
  /// Includes:
  /// - true leaves (no children), and
  /// - non-leaf sections that own [verses] refs not present in any child
  ///   subtree.
  ///
  /// The second case handles "dangling" refs on parent nodes (e.g. 9.2bcd on
  /// 4.6.2.1.1.3) so those sections are reachable by key navigation.
  /// Result is cached after first computation.
  List<({String path, String title, int depth})>
      getLeafSectionsByVerseOrderSync() {
    if (_cachedLeafSections != null) return _cachedLeafSections!;
    _ensureSectionToRefsIndex();
    final sections = _map?['sections'];
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
          Set<String>.from(_sectionToRefsIndex?[path] ?? const <String>{});
      final subtreeRefs = <String>{...sectionRefs, ...childRefs};
      final ownRefs =
          Set<String>.from(_sectionOwnRefsIndex?[path] ?? const <String>{});
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

    for (final s in sections) {
      visit(s, 0);
    }
    withFirst.sort((a, b) => _compareVerseRefsFull(a.firstRef, b.firstRef));
    _cachedLeafFirstRefs = {for (final e in withFirst) e.path: e.firstRef};
    _cachedLeafSections = withFirst
        .map((e) => (path: e.path, title: e.title, depth: e.depth))
        .toList();
    return _cachedLeafSections!;
  }

  /// Sections with first verse, sorted by verse order. For arrow-key navigation.
  /// Deduplicates sections that share the same base verse (e.g. 9.1ab and 9.1cd)
  /// so we don't step through each split-verse segment.
  /// Result is cached after first computation.
  List<({String path, String title, int depth})> getSectionsByVerseOrderSync() {
    if (_cachedSectionsByVerseOrder != null) {
      return _cachedSectionsByVerseOrder!;
    }
    final flat = getFlatSectionsSync();
    final withFirst =
        <({String path, String title, int depth, String firstRef})>[];
    for (final s in flat) {
      final ref = getFirstVerseForSectionSync(s.path);
      if (ref != null && ref.isNotEmpty) {
        withFirst
            .add((path: s.path, title: s.title, depth: s.depth, firstRef: ref));
      }
    }
    // Full ordering makes same-base split refs deterministic before dedupe.
    withFirst.sort((a, b) => _compareVerseRefsFull(a.firstRef, b.firstRef));
    // Keep one section per (chapter, verse) - skip 9.1cd when we already have 9.1ab
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
    _cachedSectionsByVerseOrder = deduped;
    return _cachedSectionsByVerseOrder!;
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

  /// Returns the hierarchy for the verse at [index]. Uses BcvVerseService to resolve ref.
  Future<List<Map<String, String>>> getHierarchyForVerseIndex(int index) async {
    final ref = BcvVerseService.instance.getVerseRef(index);
    if (ref == null) return [];
    return getHierarchyForVerse(ref);
  }

  /// Builds a reverse index from section path -> set of verse refs. Called once lazily.
  void _ensureSectionToRefsIndex() {
    if (_sectionToRefsIndex != null && _sectionOwnRefsIndex != null) return;
    _sectionToRefsIndex ??= {};
    _sectionOwnRefsIndex ??= {};
    _sectionToRefsIndex!.clear();
    _sectionOwnRefsIndex!.clear();
    final verseToPath = _map?['verseToPath'];
    if (verseToPath is Map) {
      for (final e in verseToPath.entries) {
        final path = e.value;
        if (path is! List) continue;
        final ref = e.key.toString();
        for (final item in path) {
          if (item is Map) {
            final s = (item['section'] ?? item['path'] ?? '').toString();
            if (s.isNotEmpty) {
              (_sectionToRefsIndex![s] ??= {}).add(ref);
            }
          }
        }
      }
    }
    // Index direct section ownership from sections.verses, then merge into the
    // section+descendants index.
    final sections = _map?['sections'];
    if (sections is List) {
      for (final s in sections) {
        _walkSectionsForRefs(s, _sectionOwnRefsIndex!);
      }
      for (final e in _sectionOwnRefsIndex!.entries) {
        (_sectionToRefsIndex![e.key] ??= {}).addAll(e.value);
      }
    }
  }

  /// Returns verse refs whose path contains [sectionPath] (section + descendants).
  /// Uses a pre-built reverse index for O(1) lookup.
  Set<String> getVerseRefsForSectionSync(String sectionPath) {
    if (_map == null || sectionPath.isEmpty) return {};
    _ensureSectionToRefsIndex();
    return _sectionToRefsIndex?[sectionPath] ?? {};
  }

  /// Returns only the refs directly owned by [sectionPath] (section's
  /// sections.verses entries), not descendant refs.
  Set<String> getOwnVerseRefsForSectionSync(String sectionPath) {
    if (_map == null || sectionPath.isEmpty) return {};
    _ensureSectionToRefsIndex();
    return _sectionOwnRefsIndex?[sectionPath] ?? {};
  }

  /// Returns refs from the section tree only: [sectionPath] own refs plus all
  /// descendants' own refs from `sections[].verses`.
  ///
  /// This excludes refs that appear only through `verseToPath` ancestor
  /// propagation and is safer for Textual Structure popups.
  Set<String> getTreeVerseRefsForSectionSync(String sectionPath) {
    if (_map == null || sectionPath.isEmpty) return {};
    _ensureSectionToRefsIndex();
    final ownIndex = _sectionOwnRefsIndex;
    if (ownIndex == null || ownIndex.isEmpty) return {};

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

  List<({String path, String title, int depth})>? _flatSections;
  List<({String path, String title, int depth})>? _cachedLeafSections;
  Map<String, String>? _cachedLeafFirstRefs;
  List<({String path, String title, int depth})>? _cachedSectionsByVerseOrder;
  Map<String, Set<String>>? _sectionToRefsIndex;
  Map<String, Set<String>>? _sectionOwnRefsIndex;

  /// Pre-computed section path -> verse range string (e.g. "v1.1ab", "v1.2-1.3").
  /// Built once on first access; use for overview tree labels.
  Map<String, String>? _sectionToVerseRange;

  /// Returns a map of section path -> short verse range string for display in the overview.
  /// E.g. "v1.1ab", "v1.2-1.3", "v4.2-v4.3". Computed once and cached.
  /// Call after _ensureLoaded().
  Map<String, String> getSectionVerseRangeMapSync() {
    if (_sectionToVerseRange != null) return _sectionToVerseRange!;
    _ensureSectionToRefsIndex();
    final flat = getFlatSectionsSync();
    final out = <String, String>{};
    for (final section in flat) {
      final path = section.path;
      final ownRefs = getOwnVerseRefsForSectionSync(path);
      final treeRefs = getTreeVerseRefsForSectionSync(path);
      final refs = (ownRefs.isNotEmpty
              ? ownRefs
              : treeRefs.isNotEmpty
                  ? treeRefs
                  : getVerseRefsForSectionSync(path))
          .toList()
        ..sort(_compareVerseRefsFull);
      if (refs.isEmpty) continue;
      out[path] = _formatVerseRange(refs);
    }
    _sectionToVerseRange = out;
    return _sectionToVerseRange!;
  }

  /// Format sorted refs as "v1.1ab" or "v1.2-1.3", "v4.2-v4.3".
  static String _formatVerseRange(List<String> refs) {
    if (refs.isEmpty) return '';
    if (refs.length == 1) return 'v${refs.first}';
    final first = refs.first;
    final last = refs.last;
    return 'v$first-$last';
  }

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
    if (_map == null ||
        !BcvVerseService.baseVerseRefPattern.hasMatch(baseRef)) {
      return [];
    }
    final verseToPath = _map!['verseToPath'];
    if (verseToPath == null || verseToPath is! Map) return [];

    // Prefer direct ownership from sections.verses over verseToPath-derived
    // entries. This avoids stale/wrong segment aliases in verseToPath
    // (e.g. 9.4ab/9.4cd when sections own 9.4abc/9.4d).
    _ensureSectionToRefsIndex();
    final ownSplit =
        _collectSplitSegmentsFromIndex(_sectionOwnRefsIndex, baseRef);
    if (ownSplit.isNotEmpty) return ownSplit;
    // If sections own the unsuffixed base ref (e.g. "9.110"), treat it as a
    // whole verse and ignore verseToPath split aliases (e.g. 9.110ab/cd).
    if (_sectionOwnRefsIndex != null) {
      for (final refs in _sectionOwnRefsIndex!.values) {
        if (refs.contains(baseRef)) return [];
      }
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

    // Generic fallback: scan the full index for segment refs with contiguous
    // suffixes (a..d) split across distinct sections.
    return _collectSplitSegmentsFromIndex(_sectionToRefsIndex, baseRef);
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
        if (BcvVerseService.lineRangeForSegmentRef(ref, 4) == null) continue;
        byRef.putIfAbsent(ref, () => sectionPath);
      }
    }
    if (byRef.length < 2) return [];
    final distinctSections = byRef.values.toSet();
    if (distinctSections.length < 2) return [];

    final out =
        byRef.entries.map((e) => (ref: e.key, sectionPath: e.value)).toList();
    out.sort((a, b) {
      final ra = BcvVerseService.lineRangeForSegmentRef(a.ref, 4);
      final rb = BcvVerseService.lineRangeForSegmentRef(b.ref, 4);
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
  List<Map<String, String>> getHierarchyForVerseSync(String ref) {
    if (_map == null) return [];
    return _pathForRef(ref) ?? [];
  }
}
