import '../services/bcv_verse_service.dart';
import '../services/verse_hierarchy_service.dart';

/// Pre-warms BCV verse data and hierarchy so the read/overview screens open quickly.
/// Call from landing, text options, or overview when the user may navigate to BCV content.
Future<void> preloadBcvAndHierarchy() async {
  await Future.wait([
    BcvVerseService.instance.preload(),
    VerseHierarchyService.instance.preload(),
  ]);
}
