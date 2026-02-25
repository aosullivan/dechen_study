import 'dart:async';

import '../config/study_text_config.dart';
import '../services/verse_service.dart';
import '../services/commentary_service.dart';
import '../services/verse_hierarchy_service.dart';

/// Pre-warms verse data and hierarchy for [textId] so the read/overview screens open quickly.
/// Call when the user is entering a study-text flow (e.g. TextOptionsScreen with that textId).
Future<void> preloadForText(String textId) async {
  final config = getStudyText(textId);
  if (config == null || !config.hasFullStudySupport) return;
  await Future.wait([
    VerseService.instance.preload(textId),
    VerseHierarchyService.instance.preload(textId),
  ]);
  // Optionally preload commentary for daily verse.
  unawaited(CommentaryService.instance.getCommentaryForRef(textId, '1.1'));
}
