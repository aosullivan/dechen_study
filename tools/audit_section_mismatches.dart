// Audit script: find verses/sections that may be wrong in verse_hierarchy_map.json
// because the overview title doesn't match the commentary mapping title.
//
// Run: dart run tools/audit_section_mismatches.dart
//
// Compares section titles in overviews-pages (EOS).txt vs verse_commentary_mapping.txt.
// Reports mapping headings that failed to match or matched only via fuzzy/prefix,
// and suggests which overview section they may correspond to.

import 'dart:convert';
import 'dart:io';

import 'shared/overview_parser.dart';

const overviewPath = 'texts/overviews-pages (EOS).txt';
const mappingPath = 'texts/verse_commentary_mapping.txt';
const jsonPath = 'texts/verse_hierarchy_map.json';

/// Word overlap score (0-1)
double wordOverlap(String a, String b) {
  final as = normalize(a).split(RegExp(r'\s+')).where((w) => w.length >= 2).toSet();
  final bs = normalize(b).split(RegExp(r'\s+')).where((w) => w.length >= 2).toSet();
  if (as.isEmpty || bs.isEmpty) return 0;
  return as.intersection(bs).length / (as.length + bs.length - as.intersection(bs).length);
}

/// Check if one string contains the other (normalized)
bool oneContainsOther(String a, String b) {
  final an = normalize(a);
  final bn = normalize(b);
  return an.contains(bn) || bn.contains(an);
}

void main() async {
  final overviewContent = await File(overviewPath).readAsString();
  final mappingContent = await File(mappingPath).readAsString();
  final jsonContent = await File(jsonPath).readAsString();
  final json = jsonDecode(jsonContent) as Map<String, dynamic>;

  final overviewSections = parseOverviewSections(overviewContent);
  final verseToPath = (json['verseToPath'] as Map<String, dynamic>).cast<String, dynamic>();

  // Build mapping: (verse -> heading, context)
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
      if (i + 1 < mappingLines.length && isSectionHeading(mappingLines[i + 1])) {
        targetHeading = extractHeading(mappingLines[i + 1]);
      } else {
        for (var j = i - 1; j >= 0; j--) {
          if (isSectionHeading(mappingLines[j])) {
            targetHeading = extractHeading(mappingLines[j]);
            break;
          }
        }
      }
    }
    if (targetHeading != null) {
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

  // Build overview lookup: norm -> sections
  final overviewByNorm = <String, List<Map<String, dynamic>>>{};
  for (final s in overviewSections) {
    final n = s['titleNorm'] as String;
    overviewByNorm.putIfAbsent(n, () => []).add(s);
  }

  // Find verses that are NOT in verseToPath (unmapped)
  final unmappedVerses = verseToHeading.keys
      .where((ref) => !verseToPath.containsKey(ref))
      .toList()
    ..sort(compareVerseRefs);

  print('=== UNMAPPED VERSES (in mapping but not in verseToPath) ===');
  if (unmappedVerses.isEmpty) {
    print('None.');
  } else {
    final byHeading = <String, List<String>>{};
    for (final ref in unmappedVerses) {
      final h = verseToHeading[ref] ?? '?';
      byHeading.putIfAbsent(h, () => []).add(ref);
    }
    for (final e in byHeading.entries) {
      print('  Heading: ${e.key}');
      print('    Verses: ${e.value.join(", ")}');
      // Suggest overview sections that might match
      final mappingNum = getLeadingNumber(e.key);
      final mappingTitleNorm = normalize(stripNumberPrefix(e.key));
      final candidates = <Map<String, dynamic>>[];
      for (final ov in overviewSections) {
        final ovNorm = ov['titleNorm'] as String;
        if (ovNorm == mappingTitleNorm) {
          candidates.add({...ov, 'reason': 'exact'});
        } else if (mappingNum != null && ov['num'] == mappingNum &&
            (oneContainsOther(ov['title'] as String, stripNumberPrefix(e.key)) ||
                wordOverlap(ov['title'] as String, stripNumberPrefix(e.key)) > 0.3)) {
          candidates.add({...ov, 'reason': 'same number + overlap'});
        } else if (oneContainsOther(ov['title'] as String, stripNumberPrefix(e.key))) {
          candidates.add({...ov, 'reason': 'substring'});
        }
      }
      if (candidates.isNotEmpty) {
        print('    Possible overview match(es):');
        for (final c in candidates.take(3)) {
          print('      - ${c['path']}: "${c['title']}" (${c['reason']})');
        }
      }
      print('');
    }
  }

  // Find overview sections with empty verses that have a mapping heading with same number
  print('=== OVERVIEW SECTIONS WITH NO VERSES (might be title mismatch) ===');
  final sectionToVerses = <String, List<String>>{};
  void collectVerses(Map<String, dynamic> node) {
    final path = node['path'] as String?;
    if (path != null && path.isNotEmpty) {
      final verses = (node['verses'] as List<dynamic>?)?.cast<String>() ?? [];
      sectionToVerses[path] = verses;
    }
    for (final c in (node['children'] as List<dynamic>?) ?? []) {
      collectVerses(c as Map<String, dynamic>);
    }
  }
  for (final s in (json['sections'] as List<dynamic>)) {
    collectVerses(s as Map<String, dynamic>);
  }

  final emptySections = sectionToVerses.entries
      .where((e) => e.value.isEmpty)
      .map((e) => e.key)
      .toList();

  // Get title for each section from overview
  final pathToOverview = <String, Map<String, dynamic>>{};
  for (final s in overviewSections) {
    pathToOverview[s['path'] as String] = s;
  }

  var reportedEmpty = 0;
  for (final path in emptySections) {
    final ov = pathToOverview[path];
    if (ov == null) continue;
    final title = ov['title'] as String;
    final num = ov['num'] as String?;
    final titleNorm = ov['titleNorm'] as String;

    // Look for mapping headings that could be this section
    final mappingCandidates = <Map<String, dynamic>>[];
    for (final entry in verseToHeading.entries) {
      final mTitle = stripNumberPrefix(entry.value);
      final mNorm = normalize(mTitle);
      final mNum = getLeadingNumber(entry.value);
      if (mNum == num && mNorm != titleNorm) {
        if (oneContainsOther(title, mTitle) || wordOverlap(title, mTitle) > 0.2) {
          mappingCandidates.add({
            'heading': entry.value,
            'verse': entry.key,
            'overlap': wordOverlap(title, mTitle),
          });
        }
      }
    }
    if (mappingCandidates.isNotEmpty) {
      reportedEmpty++;
      print('  $path: "$title"');
      print('    Mapping has similar but different:');
      for (final c in mappingCandidates.take(3)) {
        print('      - "${c['heading']}" (verse ${c['verse']})');
      }
      print('');
    }
  }
  if (reportedEmpty == 0) {
    print('  None with clear mapping alternatives.');
  }

  // Focused: overview title is a PREFIX of mapping title (short overview, full mapping)
  // This is the pattern that caused 3.2.1.5/6/7: "Requesting" vs "Requesting the wheel..."
  print('=== LIKELY TITLE MISMATCH: Overview shorter than mapping (prefix) ===');
  final prefixMismatches = <Map<String, dynamic>>[];
  for (final ov in overviewSections) {
    final ovTitle = ov['title'] as String;
    final ovNorm = ov['titleNorm'] as String;
    if (ovNorm.length < 5) continue; // skip very short generic titles
    for (final entry in verseToHeading.entries) {
      final mTitle = stripNumberPrefix(entry.value);
      final mNorm = normalize(mTitle);
      if (mNorm == ovNorm) continue; // exact match, skip
      if (mNorm.startsWith(ovNorm) && mNorm.length > ovNorm.length + 5) {
        // mapping title starts with overview title and is meaningfully longer
        final path = ov['path'] as String;
        final hasVerses = (sectionToVerses[path] ?? []).isNotEmpty;
        if (!hasVerses || !verseToPath.containsKey(entry.key)) {
          prefixMismatches.add({
            'path': path,
            'overview': ovTitle,
            'mapping': entry.value,
            'verse': entry.key,
          });
        }
      }
    }
  }
  // Dedupe by (path, mapping)
  final seen = <String>{};
  for (final m in prefixMismatches) {
    final key = '${m['path']}|${m['mapping']}';
    if (seen.contains(key)) continue;
    seen.add(key);
    print('  ${m['path']}: "${m['overview']}"');
    print('    Mapping (fuller): "${m['mapping']}" (verse ${m['verse']})');
  }
  if (seen.isEmpty) {
    print('  None found.');
  }

  // Summary: mapping headings that don't exactly match any overview title
  print('');
  print('=== MAPPING HEADINGS WITHOUT EXACT OVERVIEW MATCH ===');
  final uniqueHeadings = verseToHeading.values.toSet();
  final noExactMatch = <String>[];
  for (final h in uniqueHeadings) {
    final norm = normalize(stripNumberPrefix(h));
    if (!overviewByNorm.containsKey(norm)) {
      noExactMatch.add(h);
    }
  }
  noExactMatch.sort();
  if (noExactMatch.isEmpty) {
    print('  All mapping headings have an exact overview match.');
  } else {
    for (final h in noExactMatch.take(50)) {
      final verses = verseToHeading.entries
          .where((e) => e.value == h)
          .map((e) => e.key)
          .toList()
        ..sort((a, b) => a.compareTo(b));
      final inJson = verses.any((v) => verseToPath.containsKey(v));
      print('  "$h"');
      print('    Verses: ${verses.take(10).join(", ")}${verses.length > 10 ? "..." : ""}');
      print('    In JSON: ${inJson ? "yes" : "NO"}');
    }
    if (noExactMatch.length > 50) {
      print('  ... and ${noExactMatch.length - 50} more');
    }
  }
}
