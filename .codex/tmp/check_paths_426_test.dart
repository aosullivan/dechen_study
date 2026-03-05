import 'package:flutter_test/flutter_test.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paths', () async {
    const textId = 'bodhicaryavatara';
    final h = VerseHierarchyService.instance;
    await h.getHierarchyForVerse(textId, '1.1');
    for (final ref in ['4.26ab', '4.26c', '4.26d', '4.28cd']) {
      final p = h.getHierarchyForVerseSync(textId, ref);
      final section = p.isEmpty ? '' : ((p.last['section'] ?? p.last['path'] ?? '').toString());
      // ignore: avoid_print
      print('$ref => $section');
    }
  });
}
