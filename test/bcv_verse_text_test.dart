import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/screens/landing/bcv/bcv_verse_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final verseStyle = const TextStyle(
    fontFamily: 'Lora',
    fontSize: 15,
    height: 1.6,
  );

  bool fitsSingleVisualLine(String text, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: verseStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final lineCount = painter.computeLineMetrics().length;
    painter.dispose();
    return lineCount <= 1;
  }

  String normalizeSpaces(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  group('VerseLineBreaker', () {
    test(
        'Verse 7.9: wrapped line splits so "and" and "red," are separate continuations',
        () {
      const line = 'Overcome with misery, their eyes swollen and red,';
      const maxWidth = 220.0;

      final result =
          VerseLineBreaker.getVisualLineSegments(line, verseStyle, maxWidth);

      expect(result.segments.length, greaterThanOrEqualTo(2),
          reason: 'Line should wrap to at least 2 segments at narrow width');

      // Bug case: first segment must NOT include "and" (continuation was wrongly in first segment).
      expect(
        result.segments.first,
        isNot(contains('and')),
        reason:
            'First segment must not include "and" (continuation should be indented on its own line)',
      );

      // Last segment should contain "red".
      expect(result.segments.last, contains('red'));
    });

    test('Commentary prose: "sufferings" is a continuation line', () {
      const line = 'What can be said of the unbearable sufferings';
      const maxWidth = 240.0;

      final result =
          VerseLineBreaker.getVisualLineSegments(line, verseStyle, maxWidth);

      expect(result.segments.length, greaterThanOrEqualTo(2),
          reason: 'Line should wrap so "sufferings" is on its own line');
      expect(result.segments.last.trim(), equals('sufferings'));
    });

    test('"Though drawn..." wraps with continuations indented', () {
      const line =
          'Though drawn by his generosity, will not want to be around him.';
      const maxWidth = 220.0;

      final result =
          VerseLineBreaker.getVisualLineSegments(line, verseStyle, maxWidth);

      expect(result.segments.length, greaterThanOrEqualTo(2));
      // First segment must not contain "want" (was wrongly flush in bug).
      expect(
        result.segments.first,
        isNot(contains('want')),
        reason: 'First segment must not include "want"',
      );
      expect(result.segments.last, contains('him.'));
    });

    test('single line does not split', () {
      const line = 'Short line';
      final result =
          VerseLineBreaker.getVisualLineSegments(line, verseStyle, 400);

      expect(result.segments, hasLength(1));
      expect(result.segments.single, equals(line));
    });

    test('empty line returns empty segments', () {
      final result =
          VerseLineBreaker.getVisualLineSegments('', verseStyle, 200);
      expect(result.segments, isEmpty);
    });

    test('three-line wraps respect continuation width and preserve text', () {
      const line =
          'Although a person may possess caste, good appearance and learning.';
      const maxWidth = 220.0;
      const continuationIndent = 24.0;

      final result = VerseLineBreaker.getVisualLineSegments(
        line,
        verseStyle,
        maxWidth,
        continuationIndent: continuationIndent,
      );

      expect(result.segments.length, greaterThanOrEqualTo(3));

      for (var i = 0; i < result.segments.length; i++) {
        final width = i == 0 ? maxWidth : maxWidth - continuationIndent;
        expect(
          fitsSingleVisualLine(result.segments[i], width),
          isTrue,
          reason:
              'Segment ${i + 1} should not re-wrap at its paint width (prevents overlap on 3+ lines)',
        );
      }

      expect(
        normalizeSpaces(result.segments.join(' ')),
        normalizeSpaces(line),
      );
    });
  });

  group('BcvVerseText widget', () {
    testWidgets('pumps and wraps verse at narrow width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: BcvVerseText(
                text: 'Overcome with misery, their eyes swollen and red,',
                style: verseStyle,
                wrapIndent: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BcvVerseText), findsOneWidget);
      final verseFinder = find.byType(BcvVerseText);
      expect(tester.getSize(verseFinder).height,
          greaterThan(verseStyle.fontSize! * verseStyle.height!),
          reason: 'Height should reflect multiple lines');
    });

    testWidgets('logical newlines create separate blocks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: BcvVerseText(
                text: 'First line\nSecond line',
                style: verseStyle,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BcvVerseText), findsOneWidget);
      expect(find.text('First line'), findsOneWidget);
      expect(find.text('Second line'), findsOneWidget);
    });
  });
}
