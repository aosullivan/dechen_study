// Pre-parse bcv-root into JSON for fast runtime loading.
// Run: dart run tools/build_bcv_parsed.dart
// Output: texts/bcv_parsed.json
//
// Run this whenever texts/bcv-root changes. The read screen loads the JSON
// directly instead of parsing at runtime.

import 'dart:convert';
import 'dart:io';

const bcvRootPath = 'texts/bcv-root';
const outputPath = 'texts/bcv_parsed.json';

/// Parses bcv-root format into verses, captions, refs, chapters.
Map<String, dynamic> parseBcvRoot(String content) {
  final chapterTitleOnly = RegExp(r'^Chapter (\d+):\s*(.+)\s*$');
  final verseRefPattern = RegExp(r'\[(\d+)\.(\d+)\]');

  String? extractCaption(String block) {
    final match = verseRefPattern.allMatches(block).lastOrNull;
    if (match == null) return null;
    return 'Chapter ${match.group(1)}, Verse ${match.group(2)}';
  }

  String? extractRef(String block) {
    final match = verseRefPattern.allMatches(block).lastOrNull;
    if (match == null) return null;
    return '${match.group(1)}.${match.group(2)}';
  }

  String stripMarkers(String text) {
    return text.replaceAll(verseRefPattern, '').trimRight();
  }

  content = content.replaceAll(RegExp(r'[\uFEFF\x0C]'), '');
  content = content.replaceAll(RegExp(r'\r\n?'), '\n');
  final blocks = content.split(RegExp(r'\n\s*\n'));
  final verses = <String>[];
  final captions = <String?>[];
  final refs = <String?>[];
  final chapterStarts = <List<dynamic>>[];

  for (final block in blocks) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) continue;
    final lines = trimmed
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    var pendingVerseLines = <String>[];
    for (final line in lines) {
      final chapterMatch = chapterTitleOnly.firstMatch(line);
      if (chapterMatch != null) {
        if (pendingVerseLines.isNotEmpty) {
          final joined = pendingVerseLines.join('\n');
          captions.add(extractCaption(joined));
          refs.add(extractRef(joined));
          verses.add(stripMarkers(joined));
          pendingVerseLines = [];
        }
        chapterStarts.add([
          int.parse(chapterMatch.group(1)!),
          chapterMatch.group(2)!.trim(),
          verses.length,
        ]);
        continue;
      }
      pendingVerseLines.add(line);
    }
    if (pendingVerseLines.isNotEmpty) {
      final joined = pendingVerseLines.join('\n');
      captions.add(extractCaption(joined));
      refs.add(extractRef(joined));
      verses.add(stripMarkers(joined));
    }
  }

  final chapters = <Map<String, dynamic>>[];
  for (var i = 0; i < chapterStarts.length; i++) {
    final start = chapterStarts[i];
    final endIndex = i + 1 < chapterStarts.length
        ? chapterStarts[i + 1][2] as int
        : verses.length;
    chapters.add({
      'number': start[0] as int,
      'title': start[1] as String,
      'startVerseIndex': start[2] as int,
      'endVerseIndex': endIndex,
    });
  }

  return {
    'verses': verses,
    'captions': captions,
    'refs': refs,
    'chapters': chapters,
  };
}

void main() {
  final root = File(bcvRootPath);
  if (!root.existsSync()) {
    stderr.writeln('Error: $bcvRootPath not found. Run from project root.');
    exit(1);
  }

  final content = root.readAsStringSync();
  final result = parseBcvRoot(content);

  final output = File(outputPath);
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(result),
    flush: true,
  );

  final verseCount = (result['verses'] as List).length;
  print('Wrote $outputPath ($verseCount verses)');
}
