import 'package:flutter_test/flutter_test.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';
import 'package:dechen_study/services/verse_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inspect 4.26 split sections', () async {
    const textId = 'bodhicaryavatara';
    final hierarchy = VerseHierarchyService.instance;
    final verse = VerseService.instance;
    await verse.getChapters(textId);
    await hierarchy.getHierarchyForVerse(textId, '1.1');

    final segs = hierarchy.getSplitVerseSegmentsSync(textId, '4.26');
    // ignore: avoid_print
    print('segments: ${segs.map((s) => '${s.ref}:${s.sectionPath}').join(', ')}');

    for (final ref in ['4.26ab', '4.26c', '4.26d']) {
      final path = hierarchy.getHierarchyForVerseSync(textId, ref);
      final section = path.isEmpty
          ? ''
          : ((path.last['section'] ?? path.last['path'] ?? '').toString());
      final own = hierarchy.getOwnVerseRefsForSectionSync(textId, section).toList()..sort();
      final all = hierarchy.getVerseRefsForSectionSync(textId, section).toList()..sort();
      // ignore: avoid_print
      print('ref=$ref section=$section');
      // ignore: avoid_print
      print('  own=$own');
      // ignore: avoid_print
      print('  all=$all');
    }

    expect(segs.any((s) => s.ref == '4.26c'), isTrue);
    expect(segs.any((s) => s.ref == '4.26d'), isTrue);
  });
}
