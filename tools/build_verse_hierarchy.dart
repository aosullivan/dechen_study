// Build verse hierarchy mapping from overview (definitive) + verse_commentary_mapping (matching aid).
// Run: dart run tools/build_verse_hierarchy.dart
// Output: texts/verse_hierarchy_map.json
//
// Structure: overview as JSON tree. Each section node has title, verses[], children[].
// Verses are grouped under their section. verseToPath provides quick lookup for the app.

import 'dart:convert';
import 'dart:io';

import 'shared/overview_parser.dart';

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

/// Word set for flexible matching (words of length 3+).
Set<String> _wordSet(String s) {
  return normalize(s).split(RegExp(r'\s+')).where((w) => w.length >= 3).toSet();
}

/// True if title words have significant overlap with context (3+ words or 50%+).
bool _contextMatchesTitle(Set<String> contextWords, String title) {
  final titleWords = _wordSet(title);
  if (titleWords.isEmpty) return false;
  final overlap = titleWords.intersection(contextWords);
  return overlap.length >= 3 || overlap.length >= titleWords.length ~/ 2;
}

/// When multiple nodes share the same title, pick the one whose parent or sibling
/// matches the context headings from the mapping. On tie, use verse proximity if [ref] given.
OverviewNode? _disambiguateByContext(List<OverviewNode> candidates, List<String> context,
    {String? ref}) {
  if (context.isEmpty) return null;
  final contextNorm = context.map((h) => normalize(stripNumberPrefix(h))).toSet();
  final contextWords = contextNorm.expand((s) => s.split(RegExp(r'\s+')).where((w) => w.length >= 3)).toSet();

  int score(OverviewNode n) {
    var s = 0;
    // Parent match (strong) - exact or flexible word overlap for similar phrasing.
    // Strip number prefix from overview titles so they match context (e.g. "1. Accepting others" -> "Accepting others").
    if (n.parent != null && n.parent!.title.isNotEmpty) {
      final parentNorm = normalize(stripNumberPrefix(n.parent!.title));
      if (contextNorm.contains(parentNorm)) {
        s += 2;
      } else if (_contextMatchesTitle(contextWords, stripNumberPrefix(n.parent!.title))) {
        s += 1;
      }
    }
    // Sibling match (also strong - e.g. "Elaboration" vs "Accomplishing it")
    final siblings = n.parent?.children ?? [];
    for (final sib in siblings) {
      if (sib != n && contextNorm.contains(normalize(stripNumberPrefix(sib.title)))) {
        s += 1;
        break;
      }
    }
    return s;
  }

  final scored = candidates.map((n) => (n, score(n))).toList();
  final bestScore = scored.map((e) => e.$2).reduce((a, b) => a >= b ? a : b);
  if (bestScore == 0) return null;
  final tied = scored.where((e) => e.$2 == bestScore).map((e) => e.$1).toList();
  if (tied.length == 1) return tied.single;
  // Tie: use verse proximity
  if (ref != null) {
    final byProx = tied.map((n) => (n, _verseProximity(ref, n))).toList();
    final best = byProx.reduce((a, b) => a.$2 <= b.$2 ? a : b);
    if (best.$2 < double.infinity) return best.$1;
  }
  return tied.first;
}


/// When the target heading has no matching node under the context's parent (overview flatter
/// than mapping), try matching a parent heading from context instead (e.g. "Its unique preeminence").
/// Do not match a node that is a sibling of any candidate (would wrongly merge Objection/Response).
OverviewNode? _matchContextParent(Map<String, List<OverviewNode>> lookup, List<String> context,
    List<OverviewNode> candidates) {
  final candidateSiblingTitles = <String>{};
  for (final c in candidates) {
    for (final sib in c.parent?.children ?? []) {
      if (sib != c) candidateSiblingTitles.add(normalize(sib.title));
    }
  }
  for (final h in context) {
    final title = stripNumberPrefix(h);
    final norm = normalize(title);
    if (candidateSiblingTitles.contains(norm)) continue; // don't match sibling
    final nodes = lookup[norm];
    if (nodes != null && nodes.length == 1) return nodes.single;
  }
  return null;
}

/// (chapter, verse) for verse ref. 8.19ab -> (8, 19).
(int, int) _parseVerseRef(String ref) {
  final m = RegExp(r'^(\d+)\.(\d+)').firstMatch(ref);
  if (m == null) return (0, 0);
  return (int.parse(m.group(1)!), int.parse(m.group(2)!));
}

/// Distance from ref to node: 0 if node has verse in same chapter within ~50 verses, else large.
double _verseProximity(String ref, OverviewNode node) {
  final (refCh, refV) = _parseVerseRef(ref);
  if (refCh == 0) return double.infinity;
  var best = double.infinity;
  for (final v in node.verses) {
    final (ch, vn) = _parseVerseRef(v);
    if (ch == refCh) {
      final d = (refV - vn).abs();
      if (d < best) best = d.toDouble();
    }
  }
  return best;
}

/// Match mapping heading to overview node. Returns (node, needsReview).
/// [context] = section headings from preceding mapping lines, for disambiguating repeated titles.
/// [ref] = verse ref for proximity tiebreaker (e.g. "9.30").
(OverviewNode?, bool) matchToOverview(String heading, Map<String, List<OverviewNode>> lookup,
    {List<String> context = const [], String? ref}) {
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
    // Disambiguate using context: parent/sibling titles from mapping
    final disambiguated = _disambiguateByContext(exact, context, ref: ref);
    if (disambiguated != null) return (disambiguated, false);
    // Verse proximity: prefer candidate whose verses are closest (same chapter, nearby verses)
    if (ref != null) {
      final byProximity = exact
          .map((n) => (n, _verseProximity(ref, n)))
          .toList();
      final bestProx = byProximity.reduce(
          (a, b) => a.$2 <= b.$2 ? a : b);
      if (bestProx.$2 < double.infinity) return (bestProx.$1, false);
    }
    // Fallback: try matching a parent heading from context (overview may be flatter than mapping)
    final parentMatch = _matchContextParent(lookup, context, exact);
    if (parentMatch != null) return (parentMatch, false);
    return (exact.first, true); // still ambiguous
  }

  // Try prefix match: prefer overview titles at least as specific as our heading.
  // Reject when norm contains entry.key but entry.key is shorter—avoids matching
  // "Showing through the scriptures..." to generic "Scripture".
  OverviewNode? prefixMatch;
  for (final entry in lookup.entries) {
    if (norm.contains(entry.key)) {
      if (entry.key.length < norm.length) continue; // skip: overview is less specific
    } else if (!entry.key.contains(norm)) continue;
    if (prefixMatch == null || entry.key.length > normalize(prefixMatch.title).length) {
      prefixMatch = entry.value.first;
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

/// Serialize node to JSON (title, verses, children). Skips root.
Map<String, dynamic> nodeToJson(OverviewNode node) {
  final verses = List<String>.from(node.verses)..sort(compareVerseRefs);
  final needsReview = List<String>.from(node.needsReviewVerses)..sort(compareVerseRefs);
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


void main() async {
  final overviewContent = await File(overviewPath).readAsString();
  final mappingContent = await File(mappingPath).readAsString();

  final root = parseOverview(overviewContent);
  final lookup = buildTitleLookup(root);

  // Parse mapping: refs on a line belong to the section heading on the NEXT line (not current).
  // Pattern: "[8.20]" or "[8.22] [8.23] [8.24]" followed by "1. Volatility" etc.
  // Also collect context (headings from preceding lines) for disambiguating repeated titles.
  final verseToHeading = <String, String>{};
  final verseToContext = <String, List<String>>{};
  final mappingLines = mappingContent.split('\n');

  for (var i = 0; i < mappingLines.length; i++) {
    final line = mappingLines[i];
    final refs = extractVerseRefs(line);
    if (refs.isEmpty) continue;

    String? targetHeading;
    if (isSectionHeading(line)) {
      targetHeading = extractHeading(line);
    } else {
      // Lookahead: refs on a line by themselves belong to the heading on the next line
      final nextIdx = i + 1;
      if (nextIdx < mappingLines.length && isSectionHeading(mappingLines[nextIdx])) {
        targetHeading = extractHeading(mappingLines[nextIdx]);
      } else {
        // Fallback: look back for last heading (refs mid-content)
        for (var j = i - 1; j >= 0; j--) {
          if (isSectionHeading(mappingLines[j])) {
            targetHeading = extractHeading(mappingLines[j]);
            break;
          }
        }
      }
    }
    if (targetHeading != null) {
      // Collect context: headings from preceding lines (for disambiguating repeated titles)
      final context = <String>[];
      for (var j = i - 1; j >= 0 && j >= i - 25; j--) {
        if (isSectionHeading(mappingLines[j])) {
          context.add(extractHeading(mappingLines[j]));
        }
      }
      for (final ref in refs) {
        verseToHeading[ref] = targetHeading;
        verseToContext[ref] = context;
      }
    }
  }

  // Manual overrides when automatic matching assigns verses to wrong sections.
  final verseToSectionOverride = <String, String>{
    '7.75': '4.4.4.2.3', // Self-control (was wrongly matching four foundations of mindfulness)
    '1.7ab': '3.1.1.1.2', // It benefits oneself
    '1.7cd': '3.1.1.1.3', // It has the power to benefit others
    '6.124': '4.3.2.1.4.3.2.2.3.2.1.5', // Confessing needless faults before the Sage
    '7.7ab': '4.4.3.2.2.4', // Impossible to hold back time
    '7.7cd': '4.4.3.2.2.5', // The time of death is too late
  };

  OverviewNode? findNodeByPath(OverviewNode n, String path) {
    if (n.path == path) return n;
    for (final c in n.children) {
      final found = findNodeByPath(c, path);
      if (found != null) return found;
    }
    return null;
  }

  void removeVerseFromAll(OverviewNode n, String ref) {
    n.verses.remove(ref);
    n.needsReviewVerses.remove(ref);
    for (final c in n.children) removeVerseFromAll(c, ref);
  }

  // Map each verse to its overview node and add to that node.
  // Process in document order (by verse ref) so verse-proximity tiebreaker works correctly.
  final sortedRefs = verseToHeading.keys.toList()
    ..sort(compareVerseRefs);
  var needsReviewCount = 0;
  for (final ref in sortedRefs) {
    if (verseToSectionOverride.containsKey(ref)) continue; // handle in override step
    final heading = verseToHeading[ref]!;
    final context = verseToContext[ref] ?? [];

    final (node, needsReview) = matchToOverview(
        heading, lookup, context: context, ref: ref);

    if (node != null) {
      node.verses.add(ref);
      if (needsReview) needsReviewCount++;
    }
  }
  // Apply overrides: assign verse to correct section (override wrong auto-match).
  for (final e in verseToSectionOverride.entries) {
    removeVerseFromAll(root, e.key);
    final node = findNodeByPath(root, e.value);
    if (node != null) node.verses.add(e.key);
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
      all.sort(compareVerseRefs);
      return all.first;
    }
    final dominant = byChapter.entries
        .reduce((a, b) => a.value.length >= b.value.length ? a : b);
    dominant.value.sort(compareVerseRefs);
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
