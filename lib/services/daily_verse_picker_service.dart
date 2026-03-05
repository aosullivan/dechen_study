import '../config/study_destination_catalog.dart';
import 'commentary_service.dart';

class DailyVersePickerService {
  DailyVersePickerService._();

  static final DailyVersePickerService instance = DailyVersePickerService._();

  String? pickDailyTextId(DateTime localDate, Set<String> selectedIds) {
    final eligible = getDailyEligibleDestinations(selectedIds)
        .map((destination) => destination.textId)
        .whereType<String>()
        .toList()
      ..sort();

    if (eligible.isEmpty) return null;

    final key = '${_dateKey(localDate)}|${eligible.join(',')}';
    final index = _positiveHash(key) % eligible.length;
    return eligible[index];
  }

  Future<CommentaryEntry?> pickDailySection(
    String textId,
    DateTime localDate,
  ) async {
    final count = await CommentaryService.instance.getSectionCount(textId);
    if (count <= 0) return null;

    final key = '${_dateKey(localDate)}|$textId';
    final index = _positiveHash(key) % count;
    return CommentaryService.instance.getSectionAtIndex(textId, index);
  }

  static String _dateKey(DateTime localDate) {
    final y = localDate.year.toString().padLeft(4, '0');
    final m = localDate.month.toString().padLeft(2, '0');
    final d = localDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Stable deterministic non-cryptographic hash for routing and daily picks.
  static int _positiveHash(String input) {
    var hash = 2166136261;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    return hash;
  }
}
