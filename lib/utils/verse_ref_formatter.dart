import '../config/study_text_config.dart';

final RegExp _baseRefPattern = RegExp(r'^(\d+)\.(\d+)', caseSensitive: false);
final RegExp _fullRefPattern =
    RegExp(r'^(\d+)\.(\d+)([a-d]*)$', caseSensitive: false);
const Map<String, Set<String>> _hiddenBaseRefsByText = {
  // Colophon is modeled internally as 1.124 for mapping, but should not display
  // as a numbered verse in the UI.
  'friendlyletter': {'1.124'},
};

bool textHasChapters(String textId) =>
    getStudyText(textId)?.hasChapters ?? true;

bool isVerseRefDisplayable(String textId, String ref) {
  final trimmed = ref.trim();
  if (trimmed.isEmpty) return false;
  final baseMatch = _baseRefPattern.firstMatch(trimmed);
  if (baseMatch == null) return true;

  final chapter = baseMatch.group(1)!;
  final verse = baseMatch.group(2)!;
  final base = '$chapter.$verse';

  // Intro/title/homage synthetic refs (0.x) are internal-only labels.
  if (chapter == '0') return false;

  final hidden = _hiddenBaseRefsByText[textId];
  if (hidden != null && hidden.contains(base)) return false;
  return true;
}

String formatVerseRefForDisplay(String textId, String ref) {
  final trimmed = ref.trim();
  if (trimmed.isEmpty) return trimmed;
  if (!isVerseRefDisplayable(textId, trimmed)) return '';
  final hasChapters = textHasChapters(textId);
  final fullMatch = _fullRefPattern.firstMatch(trimmed);
  if (fullMatch == null) {
    if (hasChapters) return trimmed;
    final baseMatch = _baseRefPattern.firstMatch(trimmed);
    if (baseMatch == null) return trimmed;
    final chapter = baseMatch.group(1)!;
    final verse = baseMatch.group(2)!;
    final suffix = trimmed.substring(baseMatch.end);
    if (chapter == '1') return '$verse$suffix';
    return '$chapter.$verse$suffix';
  }
  final chapter = fullMatch.group(1)!;
  final verse = fullMatch.group(2)!;
  final suffix = fullMatch.group(3) ?? '';
  if (hasChapters) return '$chapter.$verse$suffix';
  if (chapter == '1') return '$verse$suffix';
  return '$chapter.$verse$suffix';
}

String formatBaseVerseRefForDisplay(String textId, String ref) {
  final trimmed = ref.trim();
  if (trimmed.isEmpty) return trimmed;
  if (!isVerseRefDisplayable(textId, trimmed)) return '';
  final m = _baseRefPattern.firstMatch(trimmed);
  if (m == null) return trimmed;
  final chapter = m.group(1)!;
  final verse = m.group(2)!;
  if (textHasChapters(textId)) return '$chapter.$verse';
  if (chapter == '1') return verse;
  return '$chapter.$verse';
}

String formatVerseRangeForDisplay(String textId, List<String> refs) {
  if (refs.isEmpty) return '';
  final displayableRefs = refs
      .where((r) => isVerseRefDisplayable(textId, r))
      .toList(growable: false);
  if (displayableRefs.isEmpty) return '';

  if (displayableRefs.length == 1) {
    final single = formatVerseRefForDisplay(textId, displayableRefs.first);
    return single.isEmpty ? '' : 'v$single';
  }
  final first = formatVerseRefForDisplay(textId, displayableRefs.first);
  final last = formatVerseRefForDisplay(textId, displayableRefs.last);
  if (first.isEmpty || last.isEmpty) return '';
  if (first == last) return 'v$first';
  return 'v$first-$last';
}
