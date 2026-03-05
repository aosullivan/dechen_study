import 'package:dechen_study/services/verse_hierarchy_service.dart';
import 'package:dechen_study/services/verse_service.dart';

Future<void> main() async {
  const textId = 'bodhicaryavatara';
  final hierarchy = VerseHierarchyService.instance;
  final verses = VerseService.instance;
  await verses.getChapters(textId);
  await hierarchy.getHierarchyForVerse(textId, '1.1');

  final idx = verses.getIndexForRefWithFallback(textId, '4.26ab');
  print('index 4.26ab: $idx');

  final segs = hierarchy.getSplitVerseSegmentsSync(textId, '4.26');
  print('split segments for 4.26: ${segs.map((s)=>'${s.ref}:${s.sectionPath}').toList()}');

  for (final ref in ['4.26ab', '4.26c', '4.26d', '4.27ab']) {
    final sectionPath = hierarchy.getSectionForVerseSync(textId, ref);
    final own = hierarchy.getOwnVerseRefsForSectionSync(textId, sectionPath);
    final all = hierarchy.getVerseRefsForSectionSync(textId, sectionPath);
    print('ref=$ref section=$sectionPath');
    print('  own=$own');
    print('  all=$all');
  }
}
