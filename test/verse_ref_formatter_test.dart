import 'package:dechen_study/utils/verse_ref_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatVerseRefForDisplay', () {
    test('keeps chapter.verse for bodhicaryavatara', () {
      expect(formatVerseRefForDisplay('bodhicaryavatara', '1.79'), '1.79');
      expect(formatVerseRefForDisplay('bodhicaryavatara', '1.79cd'), '1.79cd');
      expect(
          formatBaseVerseRefForDisplay('bodhicaryavatara', '1.79cd'), '1.79');
    });

    test('drops chapter for friendly letter', () {
      expect(formatVerseRefForDisplay('friendlyletter', '1.79'), '79');
      expect(formatVerseRefForDisplay('friendlyletter', '1.79cd'), '79cd');
      expect(formatBaseVerseRefForDisplay('friendlyletter', '1.79cd'), '79');
      expect(formatVerseRefForDisplay('friendlyletter', '0.1'), '');
      expect(formatBaseVerseRefForDisplay('friendlyletter', '0.2'), '');
      expect(formatVerseRefForDisplay('friendlyletter', '1.124'), '');
      expect(formatBaseVerseRefForDisplay('friendlyletter', '1.124'), '');
    });

    test('drops chapter for king of aspirations', () {
      expect(formatVerseRefForDisplay('kingofaspirations', '1.120'), '120');
      expect(formatVerseRefForDisplay('kingofaspirations', '1.120ab'), '120ab');
      expect(
        formatBaseVerseRefForDisplay('kingofaspirations', '1.120ab'),
        '120',
      );
    });
  });

  group('formatVerseRangeForDisplay', () {
    test('formats ranges for bodhicaryavatara with chapter', () {
      expect(
        formatVerseRangeForDisplay('bodhicaryavatara', const ['1.79']),
        'v1.79',
      );
      expect(
        formatVerseRangeForDisplay('bodhicaryavatara', const ['1.79', '1.80']),
        'v1.79-1.80',
      );
    });

    test('formats ranges for friendly letter without chapter', () {
      expect(
        formatVerseRangeForDisplay('friendlyletter', const ['1.79']),
        'v79',
      );
      expect(
        formatVerseRangeForDisplay('friendlyletter', const ['1.79', '1.80']),
        'v79-80',
      );
      expect(
        formatVerseRangeForDisplay('friendlyletter', const ['0.1', '0.2']),
        '',
      );
      expect(
        formatVerseRangeForDisplay('friendlyletter', const ['0.1', '1.1']),
        'v1',
      );
      expect(
        formatVerseRangeForDisplay('friendlyletter', const ['1.123', '1.124']),
        'v123',
      );
    });
  });
}
