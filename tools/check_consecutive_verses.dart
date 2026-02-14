// Check verse_hierarchy_map.json for sections with non-consecutive verses.
// Run: dart run tools/check_consecutive_verses.dart

import 'dart:io';
import 'dart:convert';

/// Parse verse ref to (chapter, verse). Suffixes ab/cd are ignored for gap detection
/// since 8.19ab and 8.19cd belong to the same verse.
(int, int) _parseRef(String ref) {
  final m = RegExp(r'^(\d+)\.(\d+)').firstMatch(ref);
  if (m == null) return (0, 0);
  return (int.parse(m.group(1)!), int.parse(m.group(2)!));
}

/// Check if verses are consecutive within each chapter.
/// Non-consecutive = there's a gap in verse numbers (e.g. 8.71, 8.85, 8.91).
bool _areConsecutive(List<String> verses) {
  if (verses.length <= 1) return true;
  // Group by chapter, get verse numbers
  final byChapter = <int, Set<int>>{};
  for (final ref in verses) {
    final (ch, v) = _parseRef(ref);
    byChapter.putIfAbsent(ch, () => {}).add(v);
  }
  for (final entries in byChapter.entries) {
    final nums = entries.value.toList()..sort();
    for (var i = 1; i < nums.length; i++) {
      if (nums[i] - nums[i - 1] > 1) return false; // gap
    }
  }
  return true;
}

void main() async {
  final content = await File('texts/verse_hierarchy_map.json').readAsString();
  final json = jsonDecode(content) as Map<String, dynamic>;
  final sections = json['sections'] as List;

  void visit(dynamic node, String pathPrefix) {
    if (node is! Map) return;
    final title = node['title'] as String? ?? '';
    final path = node['path'] as String? ?? '';
    final verses = node['verses'] as List?;
    final children = node['children'] as List? ?? [];

    final fullPath = pathPrefix.isEmpty ? path : '$pathPrefix/$path';
    if (verses != null && verses.isNotEmpty) {
      final verseList = verses.cast<String>();
      if (!_areConsecutive(verseList)) {
        print('NON-CONSECUTIVE: $path "$title"');
        print('  verses: $verseList');
        print('');
      }
    }
    for (final c in children) visit(c, fullPath);
  }

  for (final s in sections) visit(s, '');
}
