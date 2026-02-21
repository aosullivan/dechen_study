library;

import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/services/bcv_verse_service.dart';

void main() {
  group('BcvVerseService.lineRangeForSegmentRef', () {
    test('uses exact 4-line ranges for a/bcd split', () {
      expect(BcvVerseService.lineRangeForSegmentRef('7.2a', 4), [0, 0]);
      expect(BcvVerseService.lineRangeForSegmentRef('7.2bcd', 4), [1, 3]);
    });

    test('uses exact 4-line ranges for ab/cd split', () {
      expect(BcvVerseService.lineRangeForSegmentRef('8.136ab', 4), [0, 1]);
      expect(BcvVerseService.lineRangeForSegmentRef('8.136cd', 4), [2, 3]);
    });

    test('returns null for non-segment refs', () {
      expect(BcvVerseService.lineRangeForSegmentRef('7.2', 4), isNull);
    });
  });
}
