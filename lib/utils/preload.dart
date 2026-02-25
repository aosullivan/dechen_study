import '../services/bcv_verse_service.dart';
import '../services/verse_hierarchy_service.dart';

/// Pre-warms BCV verse data and hierarchy so the read/overview screens open quickly.
/// Call only when the user is entering a Bodhicaryavatara flow (e.g. TextOptionsScreen
/// with textId bodhicaryavatara, or TextualOverviewScreen). In prod, Gateway and
/// Bodhicaryavatara are separate; loading one does not require loading the other.
Future<void> preloadBcvAndHierarchy() async {
  await Future.wait([
    BcvVerseService.instance.preload(),
    VerseHierarchyService.instance.preload(),
  ]);
}
