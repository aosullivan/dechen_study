// ignore_for_file: avoid_print
/// Ensures all verses are in existing sections and consecutive within each section,
/// using verse_commentary_mapping.txt to assign verses to sections. Does NOT add new sections.
///
/// Run from project root: dart run script/fix_consecutive_verses_from_commentary.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  final projectRoot = Directory.current;
  final jsonPath = '${projectRoot.path}/texts/verse_hierarchy_map.json';
  final commentaryPath = '${projectRoot.path}/texts/verse_commentary_mapping.txt';

  if (!await File(jsonPath).exists()) {
    print('Run from project root. Missing: texts/verse_hierarchy_map.json');
    exit(1);
  }
  if (!await File(commentaryPath).exists()) {
    print('Missing: texts/verse_commentary_mapping.txt');
    exit(1);
  }

  final map = jsonDecode(await File(jsonPath).readAsString()) as Map<String, dynamic>;
  final verseToPath = map['verseToPath'] as Map<String, dynamic>?;
  final sectionsRoot = map['sections'] as List<dynamic>?;
  if (verseToPath == null || sectionsRoot == null) {
    print('Missing verseToPath or sections');
    exit(1);
  }

  final lines = await File(commentaryPath).readAsLines();

  String normalizeTitle(String s) {
    s = s.trim();
    s = s.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    if (s.endsWith(':')) s = s.substring(0, s.length - 1);
    return s.trim();
  }

  // Match "1. Title" or "2. Something" - number then dot then space then title
  final numberedHeading = RegExp(r'^(\d+)\.\s+(.+)$');
  bool looksLikeSectionHeading(String line) {
    line = line.trim();
    if (line.isEmpty) return false;
    if (numberedHeading.hasMatch(line)) return true;
    if (RegExp(r'^[A-Za-z]').hasMatch(line) && line.length < 120) return true;
    return false;
  }

  final refInBracket = RegExp(r'\[(\d+\.\d+(?:[a-z]+)?)(?:-(\d+\.\d+(?:[a-z]+)?))?\]');
  List<String> extractRefs(String line) {
    final refs = <String>[];
    for (final m in refInBracket.allMatches(line)) {
      final a = m.group(1);
      final b = m.group(2);
      if (a != null && a.isNotEmpty) refs.add(a);
      if (b != null && b.isNotEmpty) refs.add(b);
    }
    return refs;
  }

  // Parse with section stack: "N. Title" means pop (N-1) then push Title (outline convention).
  // verse -> full path of section titles [root, ..., leaf] for disambiguation.
  final verseToSectionPath = <String, List<String>>{};
  var sectionStack = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final numbered = numberedHeading.firstMatch(line.trim());
    if (numbered != null) {
      final n = int.tryParse(numbered.group(1) ?? '') ?? 0;
      final title = normalizeTitle(numbered.group(2) ?? '');
      if (title.isNotEmpty && n >= 1) {
        // Outline: "N. Title" = Nth section at current depth; pop (N-1) then push
        for (var i = 0; i < n - 1 && sectionStack.isNotEmpty; i++) {
          sectionStack.removeLast();
        }
        sectionStack.add(title);
      }
    } else if (looksLikeSectionHeading(line.trim()) && !numberedHeading.hasMatch(line.trim())) {
      // Unnumbered heading (e.g. "Explanation" alone) - treat as new leaf under current path
      final title = normalizeTitle(line.trim());
      if (title.isNotEmpty) {
        sectionStack.add(title);
      }
    }

    final refs = extractRefs(line);
    if (refs.isNotEmpty && sectionStack.isNotEmpty) {
      for (final ref in refs) {
        verseToSectionPath[ref] = List.from(sectionStack);
      }
    }
  }

  print('Parsed ${verseToSectionPath.length} verse->section path mappings from commentary.');

  // Build flat sections and leaves
  List<({String path, String title})> flatSections = [];
  void visit(dynamic node) {
    if (node is! Map) return;
    final path = (node['path'] ?? '') as String;
    final title = (node['title'] ?? '') as String;
    if (path.isNotEmpty && title.isNotEmpty) {
      flatSections.add((path: path, title: title));
    }
    for (final c in (node['children'] as List<dynamic>? ?? [])) {
      visit(c);
    }
  }
  for (final s in sectionsRoot) {
    visit(s);
  }

  final pathSet = flatSections.map((s) => s.path).toSet();
  final leaves = flatSections.where((s) {
    return !pathSet.any((p) => p != s.path && p.startsWith('${s.path}.'));
  }).toList();

  String normalizeForMatch(String t) {
    return normalizeTitle(t).toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Build breadcrumb (list of {section, title}) for a path string
  List<Map<String, String>> breadcrumbFor(String sectionPath) {
    final parts = sectionPath.split('.');
    final out = <Map<String, String>>[];
    var prefix = '';
    for (final p in parts) {
      prefix = prefix.isEmpty ? p : '$prefix.$p';
      final hit = flatSections.where((s) => s.path == prefix).firstOrNull;
      if (hit != null) {
        out.add({'section': hit.path, 'title': hit.title});
      }
    }
    return out;
  }

  // For each leaf, get list of titles from root to leaf (for matching commentary path)
  final leafBreadcrumbTitles = <String, List<String>>{};
  for (final leaf in leaves) {
    final bc = breadcrumbFor(leaf.path);
    leafBreadcrumbTitles[leaf.path] = bc.map((e) => normalizeForMatch(e['title'] ?? '')).toList();
  }

  bool listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int chapterFromRef(String ref) {
    final m = RegExp(r'^(\d+)\.').firstMatch(ref);
    return m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
  }

  // Find leaf whose breadcrumb titles end with (or equal) commentary path.
  // Fallback: match by last title only, disambiguate by same chapter.
  String? findLeafForCommentaryPath(List<String> commentaryPath, String ref) {
    if (commentaryPath.isEmpty) return null;
    final want = commentaryPath.map(normalizeForMatch).toList();
    for (final entry in leafBreadcrumbTitles.entries) {
      final bc = entry.value;
      if (bc.length < want.length) continue;
      final suffix = bc.sublist(bc.length - want.length);
      if (suffix.length == want.length && listEquals(suffix, want)) return entry.key;
    }
    // Fallback: leaves whose last title matches commentary path's last
    final lastNorm = want.isNotEmpty ? want.last : '';
    if (lastNorm.isEmpty) return null;
    final candidates = leaves.where((l) => normalizeForMatch(l.title) == lastNorm).toList();
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first.path;
    final ch = chapterFromRef(ref);
    for (final c in candidates) {
      for (final e in verseToPath.entries) {
        if (e.value is! List) continue;
        for (final item in e.value as List) {
          if (item is Map && (item['section'] ?? item['path'] ?? '').toString() == c.path) {
            if (chapterFromRef(e.key.toString()) == ch) return c.path;
          }
        }
      }
    }
    return candidates.first.path;
  }

  var updated = 0;
  for (final entry in verseToSectionPath.entries) {
    final ref = entry.key;
    final commentaryPath = entry.value;
    final pickPath = findLeafForCommentaryPath(commentaryPath, ref);
    if (pickPath == null) continue;

    final breadcrumb = breadcrumbFor(pickPath);
    if (breadcrumb.isEmpty) continue;

    verseToPath[ref] = breadcrumb;
    updated++;
  }

  print('Updated verseToPath for $updated verses from commentary.');

  int compareVerseRefs(String a, String b) {
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

  // Rebuild "verses" arrays in tree: for each node, verses = refs whose path's leaf is this node (for leaves only we set verses; for parents we could leave [] or aggregate - the service uses verseToPath so we only need to fix leaves so the tree is consistent)
  void setVersesInTree(dynamic node) {
    if (node is! Map) return;
    final path = (node['path'] ?? '') as String;
    final children = node['children'] as List<dynamic>? ?? [];
    if (children.isNotEmpty) {
      for (final c in children) setVersesInTree(c);
      node['verses'] = [];
      return;
    }
    // Leaf: collect refs whose verseToPath ends with this path
    final refs = <String>[];
    for (final e in verseToPath.entries) {
      final pathList = e.value;
      if (pathList is! List || pathList.isEmpty) continue;
      final last = pathList.last;
      if (last is Map && (last['section'] ?? last['path'] ?? '').toString() == path) {
        refs.add(e.key.toString());
      }
    }
    refs.sort(compareVerseRefs);
    node['verses'] = refs;
  }

  for (final s in sectionsRoot) {
    setVersesInTree(s);
  }

  await File(jsonPath).writeAsString(const JsonEncoder.withIndent('  ').convert(map));
  print('Wrote $jsonPath');
}
