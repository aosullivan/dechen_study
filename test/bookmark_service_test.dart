import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dechen_study/services/bookmark_service.dart';

void main() {
  const _keyVerseIndex = 'bookmark_verse_index';
  const _keyChapterNumber = 'bookmark_chapter_number';
  const _keyVerseRef = 'bookmark_verse_ref';

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyVerseIndex);
    await sp.remove(_keyChapterNumber);
    await sp.remove(_keyVerseRef);
  });

  group('BookmarkService', () {
    test('load returns null when no bookmark saved', () async {
      final bookmark = await BookmarkService.instance.load();
      expect(bookmark, isNull);
    });

    test('save then load returns saved bookmark', () async {
      await BookmarkService.instance.save(
        verseIndex: 42,
        chapterNumber: 8,
        verseRef: '8.136',
      );
      final bookmark = await BookmarkService.instance.load();
      expect(bookmark, isNotNull);
      expect(bookmark!.verseIndex, 42);
      expect(bookmark.chapterNumber, 8);
      expect(bookmark.verseRef, '8.136');
    });

    test('save without verseRef then load returns bookmark with null verseRef', () async {
      await BookmarkService.instance.save(
        verseIndex: 1,
        chapterNumber: 1,
      );
      final bookmark = await BookmarkService.instance.load();
      expect(bookmark, isNotNull);
      expect(bookmark!.verseIndex, 1);
      expect(bookmark.chapterNumber, 1);
      expect(bookmark.verseRef, isNull);
    });

    test('overwrite save updates loaded bookmark', () async {
      await BookmarkService.instance.save(
        verseIndex: 1,
        chapterNumber: 1,
        verseRef: '1.1',
      );
      await BookmarkService.instance.save(
        verseIndex: 10,
        chapterNumber: 2,
        verseRef: '2.5',
      );
      final bookmark = await BookmarkService.instance.load();
      expect(bookmark, isNotNull);
      expect(bookmark!.verseIndex, 10);
      expect(bookmark.chapterNumber, 2);
      expect(bookmark.verseRef, '2.5');
    });
  });
}
