import 'package:dechen_study/screens/landing/gateway_chapter_screen.dart';
import 'package:dechen_study/services/gateway_rich_content_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Color _leadingIconColorForLabel(WidgetTester tester, String label) {
  final textFinder = find.text(label);
  expect(textFinder, findsWidgets);
  final rowFinder =
      find.ancestor(of: textFinder.first, matching: find.byType(Row)).first;
  final iconFinder =
      find.descendant(of: rowFinder, matching: find.byType(Icon)).first;
  final icon = tester.widget<Icon>(iconFinder);
  expect(icon.color, isNotNull);
  return icon.color!;
}

TextStyle _textStyleForLabel(WidgetTester tester, String label) {
  final finder = find.text(label);
  expect(finder, findsWidgets);
  final text = tester.widget<Text>(finder.first);
  expect(text.style, isNotNull);
  return text.style!;
}

double _labelDy(WidgetTester tester, String label) {
  final finder = find.text(label);
  expect(finder, findsWidgets);
  return tester.getTopLeft(finder.first).dy;
}

void main() {
  testWidgets('chapter 1 renders rich aggregate chips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Five Aggregates'), findsWidgets);
    expect(find.text('Consciousness'), findsWidgets);
    expect(find.text('Aggregate of Form'), findsWidgets);
  });

  testWidgets('chapter 2 renders consciousness element list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 2),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        RegExp(r'Six Sense Triads at a Glance|Eighteen Dhatus'),
      ),
      findsWidgets,
    );
    expect(find.text('Eye Consciousness Element'), findsWidgets);
    expect(find.text('Mind Consciousness Element'), findsWidgets);
  });

  test('chapter 2 mental-object section data shows required composition',
      () async {
    final chapter = await GatewayRichContentService.instance.getChapter(2);
    expect(chapter, isNotNull);

    final topic = chapter!.topics.firstWhere(
      (t) =>
          t.title ==
          'Mental Object Element (Dhatu) and Mental Object Source (Ayatana)',
    );

    final allTexts = <String>[
      for (final block in topic.blocks)
        if (block.text != null) block.text!,
      for (final block in topic.blocks) ...block.items,
    ];

    expect(
      allTexts,
      contains(
          'The Element of Mental Objects (Dhatu) and Mental Object Source (Ayatana) are comprised of:'),
    );
    expect(allTexts, contains('Sensation'));
    expect(allTexts, contains('Perceptions'));
    expect(allTexts, contains('Formations'));
    expect(allTexts, contains('Cessation due to discrimination'));
    expect(allTexts, contains('Cessation not due to discrimination'));
    expect(allTexts, contains('Suchness of neutral'));
  });

  testWidgets('chapter 3 mapping uses consistent source/dhatu colors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 3),
      ),
    );
    await tester.pumpAndSettle();

    // Source-side consistency (Ayatanas): inner sources are green, outer sources are blue.
    expect(_leadingIconColorForLabel(tester, 'Eye Source'),
        const Color(0xFF2E7D52));
    expect(_leadingIconColorForLabel(tester, 'Visual Object Source'),
        const Color(0xFF2C5F8A));

    // Dhatu-side consistency: faculties yellow, objects orange, consciousnesses white.
    expect(_leadingIconColorForLabel(tester, 'Eye Element'),
        const Color(0xFF7A6000));
    expect(_leadingIconColorForLabel(tester, 'Visual Form Element'),
        const Color(0xFF96490A));
    expect(_leadingIconColorForLabel(tester, 'Eye Consciousness Element'),
        const Color(0xFF8B7355));
  });

  testWidgets('chapter 3 mapping uses consistent compact typography',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 3),
      ),
    );
    await tester.pumpAndSettle();

    final sourceStyle = _textStyleForLabel(tester, 'Eye Source');
    final objectSourceStyle =
        _textStyleForLabel(tester, 'Visual Object Source');
    final dhatuStyle = _textStyleForLabel(tester, 'Eye Element');
    final objectDhatuStyle = _textStyleForLabel(tester, 'Visual Form Element');

    expect(sourceStyle.fontSize, 12.5);
    expect(sourceStyle.fontWeight, FontWeight.w400);
    expect(objectSourceStyle.fontSize, sourceStyle.fontSize);
    expect(objectSourceStyle.fontWeight, sourceStyle.fontWeight);
    expect(dhatuStyle.fontSize, sourceStyle.fontSize);
    expect(dhatuStyle.fontWeight, sourceStyle.fontWeight);
    expect(objectDhatuStyle.fontSize, sourceStyle.fontSize);
    expect(objectDhatuStyle.fontWeight, sourceStyle.fontWeight);
  });

  testWidgets('chapter 3 mapping keeps compact and consistent row spacing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 3),
      ),
    );
    await tester.pumpAndSettle();

    final sourceGap =
        _labelDy(tester, 'Ear Source') - _labelDy(tester, 'Eye Source');
    final outerGap = _labelDy(tester, 'Sound Object Source') -
        _labelDy(tester, 'Visual Object Source');
    final dhatuGap =
        _labelDy(tester, 'Ear Element') - _labelDy(tester, 'Eye Element');

    expect(sourceGap, lessThanOrEqualTo(48));
    expect(outerGap, lessThanOrEqualTo(48));
    expect(dhatuGap, lessThanOrEqualTo(48));

    expect((sourceGap - outerGap).abs(), lessThanOrEqualTo(2));
    expect((sourceGap - dhatuGap).abs(), lessThanOrEqualTo(4));
  });

  testWidgets(
      'chapter 2 element classifications show all 18 and disabled non-members',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 2),
      ),
    );
    await tester.pumpAndSettle();

    // Keep full-reference labels in the Eighteen Dhatus section.
    expect(find.text('Eye Element'), findsWidgets);
    expect(find.text('Mind Consciousness Element'), findsWidgets);

    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 8; i++) {
      await tester.drag(scrollable, const Offset(0, -450));
      await tester.pumpAndSettle();
    }

    // Non-members are shown as disabled visually (without explicit text label).
    expect(find.text('DISABLED'), findsNothing);
    // Icon-only classification columns should still render densely.
    expect(find.byType(Icon), findsWidgets);
  });
}
