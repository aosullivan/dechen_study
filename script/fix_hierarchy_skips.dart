// ignore_for_file: avoid_print
/// Fixes verse skips in verse_hierarchy_map.json by adding leaf sections so each
/// gap verse (e.g. 8.16, 8.17, 8.18 between 8.15 and 8.19) is the first verse of its own leaf.
///
/// Run from project root: dart run script/fix_hierarchy_skips.dart
/// Requires: dart run (no Flutter). Reads texts/verse_hierarchy_map.json, writes it back.

import 'dart:convert';
import 'dart:io';

void main() async {
  final projectRoot = Directory.current;
  if (!await File('${projectRoot.path}/texts/verse_hierarchy_map.json').exists()) {
    print('Run from project root (dechen_study)');
    exit(1);
  }
  final path = '${projectRoot.path}/texts/verse_hierarchy_map.json';
  final content = await File(path).readAsString();
  final map = jsonDecode(content) as Map<String, dynamic>;
  final verseToPath = map['verseToPath'] as Map<String, dynamic>?;
  final sectionsRoot = map['sections'] as List<dynamic>?;
  if (verseToPath == null || sectionsRoot == null) {
    print('Missing verseToPath or sections');
    exit(1);
  }

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

  (int, int) baseVerse(String ref) {
    final m = RegExp(r'^(\d+)\.(\d+)').firstMatch(ref);
    if (m == null) return (0, 0);
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  List<({String path, String title})> flatSections = [];
  void visit(dynamic node, String parentPath) {
    if (node is! Map) return;
    final path = (node['path'] ?? '') as String;
    final title = (node['title'] ?? '') as String;
    if (path.isNotEmpty && title.isNotEmpty) {
      flatSections.add((path: path, title: title));
    }
    final children = node['children'];
    if (children is List) {
      for (final c in children) {
        visit(c, path);
      }
    }
  }
  for (final s in sectionsRoot) {
    visit(s, '');
  }

  Set<String> getVerseRefsForSection(String sectionPath) {
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

  String? getFirstVerseForSection(String sectionPath) {
    final refs = getVerseRefsForSection(sectionPath);
    if (refs.isEmpty) return null;
    final sorted = refs.toList()..sort(compareVerseRefs);
    return sorted.first;
  }

  final pathSet = flatSections.map((s) => s.path).toSet();
  final leaves = flatSections.where((s) {
    return !pathSet.any((p) => p != s.path && p.startsWith('${s.path}.'));
  }).toList();

  final withFirst = <({String path, String title, String firstRef})>[];
  for (final s in leaves) {
    final ref = getFirstVerseForSection(s.path);
    if (ref != null && ref.isNotEmpty) {
      withFirst.add((path: s.path, title: s.title, firstRef: ref));
    }
  }
  withFirst.sort((a, b) => compareVerseRefs(a.firstRef, b.firstRef));

  final skips = <({String pathA, String refA, String pathB, String refB, int gap})>[];
  for (var i = 0; i < withFirst.length - 1; i++) {
    final refA = withFirst[i].firstRef;
    final refB = withFirst[i + 1].firstRef;
    final (chA, vA) = baseVerse(refA);
    final (chB, vB) = baseVerse(refB);
    if (chA != chB) continue;
    final gap = vB - vA;
    if (gap > 1) {
      skips.add((
        pathA: withFirst[i].path,
        refA: refA,
        pathB: withFirst[i + 1].path,
        refB: refB,
        gap: gap,
      ));
    }
  }

  print('Found ${skips.length} skips. Adding leaves for gap verses...');

  List<dynamic> getPathList(String ref) {
    var path = verseToPath[ref];
    if (path is List) return path;
    if (RegExp(r'^\d+\.\d+$').hasMatch(ref)) {
      for (final suffix in ['ab', 'cd', 'a', 'bcd']) {
        path = verseToPath['$ref$suffix'];
        if (path is List && path.isNotEmpty) return path;
      }
    }
    final (ch, v) = baseVerse(ref);
    if (ch == 0) return [];
    for (var offset = 1; offset <= 5; offset++) {
      if (v - offset >= 1) {
        final p = verseToPath['$ch.${v - offset}'];
        if (p is List && p.isNotEmpty) return List.from(p);
      }
      final p = verseToPath['$ch.${v + offset}'];
      if (p is List && p.isNotEmpty) return List.from(p);
    }
    return [];
  }

  Map<String, dynamic>? findNodeByPath(List<dynamic> nodes, List<String> pathParts, int index) {
    if (nodes.isEmpty || index >= pathParts.length) return null;
    final currentPath = pathParts.sublist(0, index + 1).join('.');
    for (final node in nodes) {
      if (node is! Map) continue;
      if ((node['path'] ?? '').toString() == currentPath) {
        if (index == pathParts.length - 1) return node as Map<String, dynamic>;
        final children = node['children'];
        if (children is! List) return null;
        return findNodeByPath(children, pathParts, index + 1) as Map<String, dynamic>?;
      }
    }
    return null;
  }

  int nextChildIndex(Map<String, dynamic> node) {
    final children = node['children'] as List<dynamic>? ?? [];
    if (children.isEmpty) return 1;
    int max = 0;
    for (final c in children) {
      if (c is Map) {
        final p = (c['path'] ?? '').toString();
        final parts = p.split('.');
        final last = parts.isNotEmpty ? int.tryParse(parts.last) : null;
        if (last != null && last > max) max = last;
      }
    }
    return max + 1;
  }

  final gapVersesAdded = <String>{};
  for (final skip in skips) {
    final (ch, vA) = baseVerse(skip.refA);
    final (_, vB) = baseVerse(skip.refB);
    for (var v = vA + 1; v < vB; v++) {
      final ref = '$ch.$v';
      if (gapVersesAdded.contains(ref)) continue;
      List<dynamic> pathList = getPathList(ref);
      if (pathList.isEmpty) {
        pathList = getPathList(skip.refA);
        if (pathList.isEmpty) continue;
      }
      pathList = pathList.map((e) => e is Map ? Map<String, dynamic>.from(e) : e).toList();
      final lastItem = pathList.isNotEmpty ? pathList.last : null;
      if (lastItem is! Map) continue;
      final lastSection = (lastItem['section'] ?? lastItem['path'] ?? '').toString();
      if (lastSection.isEmpty) continue;

      final pathParts = lastSection.split('.');
      final parentPath = pathParts.length > 1 ? pathParts.sublist(0, pathParts.length - 1).join('.') : '';
      final parentNode = parentPath.isEmpty
          ? null
          : findNodeByPath(sectionsRoot, pathParts.sublist(0, pathParts.length - 1), 0);
      final nodeToAddChild = parentNode ?? findNodeByPath(sectionsRoot, pathParts, 0);
      if (nodeToAddChild == null) continue;

      var children = nodeToAddChild['children'];
      if (children is! List) {
        children = [];
        nodeToAddChild['children'] = children;
      }
      final nextIdx = nextChildIndex(nodeToAddChild);
      final newPath = '${nodeToAddChild['path']}.$nextIdx';
      final newTitle = 'Verse $ref';

      children.add({
        'title': newTitle,
        'path': newPath,
        'verses': [ref],
        'children': [],
      });

      // Replace last path element so this verse is only in the new leaf (not the parent).
      final newPathList = pathList.length > 1
          ? pathList.sublist(0, pathList.length - 1)
          : pathList.sublist(0, pathList.length);
      newPathList.add({'section': newPath, 'title': newTitle});
      verseToPath[ref] = newPathList;
      gapVersesAdded.add(ref);
    }
  }

  print('Added ${gapVersesAdded.length} gap verses as new leaves.');

  final out = JsonEncoder.withIndent('  ').convert(map);
  await File(path).writeAsString(out);
  print('Wrote $path');
}
