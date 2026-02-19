// Shared overview and verse-ref parsing for build_verse_hierarchy and audit_section_mismatches.
// Use: import 'shared/overview_parser.dart';

/// Normalize title for matching: lowercase, trim, collapse whitespace, remove trailing punctuation.
String normalize(String s) {
  return s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[:\.,;]+$'), '')
      .trim();
}

/// Strip number prefix from a heading: "1.2.3. Title here" -> "Title here".
String stripNumberPrefix(String s) {
  return s.replaceFirst(RegExp(r'^\d+(\.\d+)*\.\s*'), '').trim();
}

/// Extract leading number: "5. Requesting the wheel" -> "5", "3.2.1.5" -> "3".
String? getLeadingNumber(String s) {
  final m = RegExp(r'^(\d+)(?:\.|$)').firstMatch(s.trim());
  return m?.group(1);
}

/// Parse overview content into a flat list of sections (path, title, depth, titleNorm, num).
/// Indentation = 4 spaces per level. Same format as audit_section_mismatches.
List<Map<String, dynamic>> parseOverviewSections(String content) {
  final lines = content.split('\n');
  final sections = <Map<String, dynamic>>[];
  final stack = <Map<String, dynamic>>[
    {'path': '', 'depth': -1}
  ];

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final indent = line.length - line.trimLeft().length;
    final depth = indent ~/ 4;
    final match =
        RegExp(r'^(\d+(?:\.\d+)*)\.?\s*(.*)$').firstMatch(line.trim());
    if (match == null) continue;

    final title = match.group(2)!.trim();
    if (title.isEmpty) continue;

    while (stack.length > 1 && stack.last['depth'] as int >= depth) {
      stack.removeLast();
    }
    final parent = stack.last;
    final numPart = match.group(1)!;
    final path = (parent['path'] as String).isEmpty
        ? numPart
        : '${parent['path']}.$numPart';

    final node = {
      'path': path,
      'title': title,
      'titleNorm': normalize(title),
      'depth': depth,
      'num': getLeadingNumber(numPart),
    };
    sections.add(node);
    stack.add(node);
  }
  return sections;
}

/// Extract verse refs from a line. Handles [1.5], [1.5a], [1.5-1.10] etc.
List<String> extractVerseRefs(String line) {
  final refs = <String>[];
  final matches =
      RegExp(r'\[(\d+\.\d+)([a-d]*)(?:-(\d+\.\d+)[a-d]*)?\]').allMatches(line);
  for (final m in matches) {
    final start = m.group(1)!;
    final suffix = m.group(2) ?? '';
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
      refs.add(start + suffix);
    }
  }
  // Also support standalone verse reference lines used in mapping prose, e.g.:
  // "4.44", "9.101", "10.4ab", or "9.121ab-9.121cd".
  final trimmed = line.trim();
  final bareMatch = RegExp(
    r'^(\d+\.\d+)([a-d]*)(?:-(\d+\.\d+)[a-d]*)?$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (bareMatch != null) {
    final start = bareMatch.group(1)!;
    final suffix = bareMatch.group(2) ?? '';
    final end = bareMatch.group(3);
    if (end != null) {
      final startParts = start.split('.');
      final endParts = end.split('.');
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
        refs.add(start + suffix);
      }
    } else {
      refs.add(start + suffix);
    }
  }
  return refs;
}

/// Compare two verse refs (e.g. "1.5" vs "2.3"). For sorting by chapter then verse.
int compareVerseRefs(String a, String b) {
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

bool isSectionHeading(String line) {
  return RegExp(r'^\d+(\.\d+)*\.\s+.+').hasMatch(line.trim());
}

/// Extract heading text (before colon if present).
String extractHeading(String line) {
  final t = line.trim();
  final colon = t.indexOf(':');
  return colon > 0 ? t.substring(0, colon).trim() : t;
}
