import 'package:flutter_test/flutter_test.dart';
import 'package:dechen_study/services/verse_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inspect verse 4.26 text lines', () async {
    const textId = 'bodhicaryavatara';
    final verseService = VerseService.instance;
    await verseService.getChapters(textId);
    final idx = verseService.getIndexForRefWithFallback(textId, '4.26ab')!;
    final text = verseService.getVerseAt(textId, idx)!;
    final ref = verseService.getVerseRef(textId, idx);
    // ignore: avoid_print
    print('idx=$idx ref=$ref lines=${text.split('\n').length}');
    // ignore: avoid_print
    print(text.replaceAll('\n', ' | '));
    expect(text.isNotEmpty, isTrue);
  });
}
