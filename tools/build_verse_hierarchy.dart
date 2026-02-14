// Build verse hierarchy mapping from overview (definitive) + verse_commentary_mapping (matching aid).
// Run: dart run tools/build_verse_hierarchy.dart
// Output: texts/verse_hierarchy_map.json
//
// Structure: overview as JSON tree. Each section node has title, verses[], children[].
// Verses are grouped under their section. verseToPath provides quick lookup for the app.

import 'dart:io';
import 'dart:convert';

const overviewPath = 'texts/overviews-pages (EOS).txt';
const mappingPath = 'texts/verse_commentary_mapping.txt';
const outputPath = 'texts/verse_hierarchy_map.json';

/// Overview node in the definitive hierarchy tree.
class OverviewNode {
  final String title;
  final String path;
  final int depth;
  final OverviewNode? parent;
  final List<OverviewNode> children = [];
  final List<String> verses = [];
  final List<String> needsReviewVerses = [];

  OverviewNode({
    required this.title,
    required this.path,
    required this.depth,
    this.parent,
  });

  /// Path from root to this node (list of titles).
  List<String> get pathFromRoot {
    final result = <String>[];
    OverviewNode? n = this;
    while (n != null && n.title.isNotEmpty) {
      result.insert(0, n.title);
      n = n.parent;
    }
    return result;
  }

  /// Path from root with section numbers: list of {section, title}.
  List<Map<String, String>> get pathFromRootWithNumbers {
    final result = <Map<String, String>>[];
    OverviewNode? n = this;
    while (n != null && n.title.isNotEmpty) {
      result.insert(0, {'section': n.path, 'title': n.title});
      n = n.parent;
    }
    return result;
  }
}

/// Normalize title for matching: lowercase, trim, collapse whitespace, remove trailing punctuation.
String normalize(String s) {
  return s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[:\.,;]+$'), '')
      .trim();
}

/// Parse overview into tree. Indentation = 4 spaces per level.
OverviewNode parseOverview(String content) {
  final lines = content.split('\n');
  final root = OverviewNode(title: '', path: '', depth: -1, parent: null);
  final stack = <OverviewNode>[root];

  for (final line in lines) {
    if (line.trim().isEmpty) continue;

    final indent = line.length - line.trimLeft().length;
    final depth = indent ~/ 4;

    // Extract number prefix and title. Match "1." or "1.2" or "1.2.3" at start
    final match = RegExp(r'^(\d+(?:\.\d+)*)\.?\s*(.*)$').firstMatch(line.trim());
    if (match == null) continue;

    final title = match.group(2)!.trim();
    if (title.isEmpty) continue;

    // Pop stack until we're at parent depth
    while (stack.length > 1 && stack.last.depth >= depth) {
      stack.removeLast();
    }

    final parent = stack.last;
    final path = parent.path.isEmpty ? match.group(1)! : '${parent.path}.${match.group(1)}';
    final node = OverviewNode(
      title: title,
      path: path,
      depth: depth,
      parent: parent,
    );
    parent.children.add(node);
    stack.add(node);
  }

  return root;
}

/// Build lookup: normalized title -> list of nodes (may be ambiguous).
Map<String, List<OverviewNode>> buildTitleLookup(OverviewNode root) {
  final lookup = <String, List<OverviewNode>>{};
  void visit(OverviewNode n) {
    if (n.title.isNotEmpty) {
      lookup.putIfAbsent(normalize(n.title), () => []).add(n);
    }
    for (final c in n.children) visit(c);
  }
  visit(root);
  return lookup;
}

/// Match mapping heading to overview node. Returns (node, needsReview).
(OverviewNode?, bool) matchToOverview(String heading, Map<String, List<OverviewNode>> lookup) {
  // Strip number prefix: "1. The purpose of X" -> "The purpose of X"
  var headingTitle = heading.replaceFirst(RegExp(r'^\d+(\.\d+)*\.\s*'), '').trim();
  // Strip trailing suffixes like "comprises lines 1ab:", " - line 1c", etc.
  headingTitle = headingTitle
      .replaceFirst(RegExp(r'\s*comprises lines \d+[a-d]*\s*$', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s*:?\s*$'), '')
      .replaceFirst(RegExp(r'\s*[-–—].*$'), '')
      .trim();
  final norm = normalize(headingTitle);

  final exact = lookup[norm];
  if (exact != null && exact.length == 1) {
    return (exact.single, false);
  }
  if (exact != null && exact.length > 1) {
    return (exact.first, true); // ambiguous
  }

  // Try prefix match: heading contains overview title or vice versa (use best match)
  OverviewNode? prefixMatch;
  for (final entry in lookup.entries) {
    if (norm.contains(entry.key) || entry.key.contains(norm)) {
      if (prefixMatch == null || entry.key.length > normalize(prefixMatch.title).length) {
        prefixMatch = entry.value.first;
      }
    }
  }
  if (prefixMatch != null) return (prefixMatch, true);

  // Try fuzzy match
  double bestScore = 0;
  OverviewNode? best;
  for (final node in lookup.values.expand((e) => e)) {
    final nodeNorm = normalize(node.title);
    final score = _similarity(norm, nodeNorm);
    if (score > bestScore && score > 0.5) {
      bestScore = score;
      best = node;
    }
  }
  if (best != null) return (best, true);
  return (null, true);
}

/// Simple similarity: ratio of matching words.
double _similarity(String a, String b) {
  final as = a.split(RegExp(r'\s+')).toSet();
  final bs = b.split(RegExp(r'\s+')).toSet();
  if (as.isEmpty || bs.isEmpty) return 0;
  final inter = as.intersection(bs).length;
  return inter / (as.length + bs.length - inter);
}

/// Extract verse refs from a line like "[1.1]", "[1.1ab]", "[1.18] [1.19]", "[1.34-1.35ab]"
List<String> extractVerseRefs(String line) {
  final refs = <String>[];
  final matches = RegExp(r'\[(\d+\.\d+)([a-d]*)(?:-(\d+\.\d+)[a-d]*)?\]').allMatches(line);
  for (final m in matches) {
    final start = m.group(1)!;
    final end = m.group(3);
    final startBase = start.split(RegExp(r'[a-d]')).first;
    if (end != null) {
      final endBase = end.split(RegExp(r'[a-d]')).first;
      final startParts = startBase.split('.');
      final endParts = endBase.split('.');
      if (startParts.length == 2 && endParts.length == 2) {
        final c1 = int.parse(startParts[0]);
        final v1 = int.parse(startParts[1]);
        final c2 = int.parse(endParts[0]);
        final v2 = int.parse(endParts[1]);
        for (var c = c1; c <= c2; c++) {
          final vStart = (c == c1) ? v1 : 1;
          final vEnd = (c == c2) ? v2 : 999;
          for (var v = vStart; v <= vEnd; v++) {
            refs.add('$c.$v');
          }
        }
      } else {
        refs.add(startBase);
      }
    } else {
      refs.add(startBase);
    }
  }
  return refs;
}

/// Check if line looks like a section heading: starts with "N. " or "N.M. " pattern
bool isSectionHeading(String line) {
  final t = line.trim();
  if (t.isEmpty) return false;
  return RegExp(r'^\d+(\.\d+)*\.\s+.+').hasMatch(t);
}

/// Extract the heading part (before colon if any). "1. The purpose of each section:" -> "1. The purpose of each section"
String extractHeading(String line) {
  final t = line.trim();
  final colon = t.indexOf(':');
  if (colon > 0) {
    return t.substring(0, colon).trim();
  }
  return t;
}

/// Serialize node to JSON (title, verses, children). Skips root.
Map<String, dynamic> nodeToJson(OverviewNode node) {
  final verses = List<String>.from(node.verses)..sort(_compareVerseRefs);
  final needsReview = List<String>.from(node.needsReviewVerses)..sort(_compareVerseRefs);
  final children = node.children.map(nodeToJson).toList();

  final out = <String, dynamic>{
    'title': node.title,
    'path': node.path,
    'verses': verses,
    'children': children,
  };
  if (needsReview.isNotEmpty) {
    out['needsReview'] = needsReview;
  }
  return out;
}

int _compareVerseRefs(String a, String b) {
  final ap = a.split('.');
  final bp = b.split('.');
  if (ap.length != 2 || bp.length != 2) return a.compareTo(b);
  final ac = int.tryParse(ap[0]) ?? 0;
  final av = int.tryParse(ap[1]) ?? 0;
  final bc = int.tryParse(bp[0]) ?? 0;
  final bv = int.tryParse(bp[1]) ?? 0;
  if (ac != bc) return ac.compareTo(bc);
  return av.compareTo(bv);
}

void main() async {
  final overviewContent = await File(overviewPath).readAsString();
  final mappingContent = await File(mappingPath).readAsString();

  final root = parseOverview(overviewContent);
  final lookup = buildTitleLookup(root);

  // Parse mapping: track current section heading, when we see [c.v] record verse -> heading
  final verseToHeading = <String, String>{};
  String? currentHeading;

  final mappingLines = mappingContent.split('\n');
  for (final line in mappingLines) {
    if (isSectionHeading(line)) {
      currentHeading = extractHeading(line);
    }

    final refs = extractVerseRefs(line);
    if (refs.isNotEmpty && currentHeading != null) {
      for (final ref in refs) {
        verseToHeading[ref] = currentHeading; // Use last occurrence (most specific)
      }
    }
  }

  // Map each verse to its overview node and add to that node
  var needsReviewCount = 0;
  for (final entry in verseToHeading.entries) {
    final ref = entry.key;
    final heading = entry.value;

    final (node, needsReview) = matchToOverview(heading, lookup);

    if (node != null) {
      node.verses.add(ref);
      if (needsReview) {
        node.needsReviewVerses.add(ref);
        needsReviewCount++;
      }
    }
  }

  // Build output: sections tree + verseToPath + sectionToFirstVerse for app lookup
  final verseToPath = <String, List<Map<String, String>>>{};
  void collectPaths(OverviewNode n) {
    for (final v in n.verses) {
      verseToPath[v] = n.pathFromRootWithNumbers;
    }
    for (final c in n.children) collectPaths(c);
  }
  collectPaths(root);

  // sectionToFirstVerse: for each section path, the first verse ref (for breadcrumb navigation).
  // Use minimum verse from the dominant chapter (most verses) to avoid wrong refs from fuzzy matches.
  String? getFirstVerseInNode(OverviewNode n) {
    final all = <String>[];
    void collect(OverviewNode node) {
      all.addAll(node.verses);
      for (final c in node.children) collect(c);
    }
    collect(n);
    if (all.isEmpty) return null;
    // Group by chapter, pick chapter with most verses, return its minimum verse
    final byChapter = <int, List<String>>{};
    for (final ref in all) {
      final parts = ref.split('.');
      if (parts.length == 2) {
        final ch = int.tryParse(parts[0]) ?? 0;
        byChapter.putIfAbsent(ch, () => []).add(ref);
      }
    }
    if (byChapter.isEmpty) {
      all.sort(_compareVerseRefs);
      return all.first;
    }
    final dominant = byChapter.entries
        .reduce((a, b) => a.value.length >= b.value.length ? a : b);
    dominant.value.sort(_compareVerseRefs);
    return dominant.value.first;
  }
  final sectionToFirstVerse = <String, String>{};
  void collectSectionFirstVerse(OverviewNode n) {
    if (n.title.isNotEmpty) {
      final first = getFirstVerseInNode(n);
      if (first != null) sectionToFirstVerse[n.path] = first;
    }
    for (final c in n.children) collectSectionFirstVerse(c);
  }
  collectSectionFirstVerse(root);

  // Convert to JSON-serializable format
  final verseToPathJson = <String, dynamic>{};
  for (final e in verseToPath.entries) {
    verseToPathJson[e.key] = e.value;
  }

  final sections = root.children.map(nodeToJson).toList();

  final output = <String, dynamic>{
    'sections': sections,
    'verseToPath': verseToPathJson,
    'sectionToFirstVerse': sectionToFirstVerse,
  };

  await File(outputPath).writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
  );

  final totalVerses = verseToPathJson.length;
  print('Wrote $outputPath');
  print('Top-level sections: ${sections.length}');
  print('Verses mapped: $totalVerses');
  print('Needs review: $needsReviewCount');
}
