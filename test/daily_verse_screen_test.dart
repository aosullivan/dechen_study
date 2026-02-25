library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/screens/landing/daily_verse_screen.dart';
import 'package:dechen_study/screens/landing/bcv_read_screen.dart';
import 'package:dechen_study/services/commentary_service.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';
import 'package:dechen_study/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await VerseHierarchyService.instance.getHierarchyForVerse('1.1');
  });

  Future<void> pumpDaily(
    WidgetTester tester, {
    required List<String> refs,
    int minLinesForSection = 0,
    void Function(List<String> refs)? onResolvedRefsForTest,
  }) async {
    const fullVerse = 'Because it will, in this way, pacify harm to myself\n'
        'And pacify the sufferings of others,\n'
        'I will give myself up for others,\n'
        'And embrace others as I did the self.';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
        home: DailyVerseScreen(
          randomSectionLoader: () async => CommentaryEntry(
            refsInBlock: refs,
            commentaryText: 'test',
          ),
          verseIndexForRef: (_) => 0,
          verseTextForIndex: (_) => fullVerse,
          minLinesForSection: minLinesForSection,
          onResolvedRefsForTest: onResolvedRefsForTest,
        ),
      ),
    );
  }

  Future<void> waitForDailyLoad(WidgetTester tester) async {
    final another = find.widgetWithText(OutlinedButton, 'More Verses');
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (another.evaluate().isNotEmpty) return;
    }
    expect(another, findsOneWidget,
        reason: 'Daily screen did not finish loading');
  }

  testWidgets('split ref ab renders first-half text (not blank)',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['8.136ab']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 8.136'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Because it will')), findsWidgets);
    expect(
        find.bySemanticsLabel(RegExp(r'I will give myself up for others')), findsNothing);
  });

  testWidgets('split ref cd renders second-half text',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['8.136cd']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 8.136'), findsOneWidget);
    expect(
        find.bySemanticsLabel(RegExp(r'I will give myself up for others')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'Because it will')), findsNothing);
  });

  testWidgets('split refs for same verse render verse label once',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['8.136ab', '8.136cd']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 8.136'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Because it will')), findsWidgets);
    expect(
        find.bySemanticsLabel(RegExp(r'I will give myself up for others')), findsWidgets);
  });

  testWidgets('split refs in same verse are shown once in daily view',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['1.2abc', '1.2d']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 1.2'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Because it will')), findsOneWidget);
  });

  testWidgets('full text navigation preserves split segment ref',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['8.136cd']);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Full text'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final read = tester.widget<BcvReadScreen>(find.byType(BcvReadScreen));
    expect(read.initialSegmentRef, '8.136cd');
  });

  testWidgets('full text navigation preserves split segment ref for 1.14cd',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['1.14cd']);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Full text'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final read = tester.widget<BcvReadScreen>(find.byType(BcvReadScreen));
    expect(read.initialSegmentRef, '1.14cd');
  });

  testWidgets('split ref a renders first-half text',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['7.7a']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 7.7'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Because it will')), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp(r'And pacify the')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'I will give myself up for others')),
      findsNothing,
    );
  });

  testWidgets('split ref bcd renders second-half text',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['7.7bcd']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 7.7'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'And pacify the')),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'I will give myself up for others')),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'And embrace others')),
      findsWidgets,
    );
    expect(find.bySemanticsLabel(RegExp(r'Because it will')), findsNothing);
  });

  testWidgets('short split section dedupes to one base verse when expanded',
      (WidgetTester tester) async {
    List<String>? resolvedRefs;
    await pumpDaily(
      tester,
      refs: const ['8.136ab'],
      minLinesForSection: 4,
      onResolvedRefsForTest: (refs) => resolvedRefs = refs,
    );
    await waitForDailyLoad(tester);

    expect(find.text('Could not load section'), findsNothing);
    expect(resolvedRefs, isNotNull);
    final refs136 = resolvedRefs!
        .where((r) => RegExp(r'^8\.136([a-d]+)?$').hasMatch(r))
        .toList();
    expect(refs136.length, 1,
        reason: 'Split refs for the same verse should collapse to one entry');
  });

  testWidgets('section with at least min lines does not expand',
      (WidgetTester tester) async {
    List<String>? resolvedRefs;
    await pumpDaily(
      tester,
      refs: const ['8.137'],
      minLinesForSection: 4,
      onResolvedRefsForTest: (refs) => resolvedRefs = refs,
    );
    await waitForDailyLoad(tester);

    expect(find.text('Could not load section'), findsNothing);
    expect(resolvedRefs, equals(const ['8.137']));
  });

  testWidgets('expansion keeps daily refs in the seed chapter',
      (WidgetTester tester) async {
    List<String>? resolvedRefs;
    int? indexForRef(String ref) {
      final m = RegExp(r'^(\d+)\.(\d+)', caseSensitive: false).firstMatch(ref);
      if (m == null) return null;
      final ch = int.tryParse(m.group(1)!);
      final verse = int.tryParse(m.group(2)!);
      if (ch == null || verse == null) return null;
      return (ch * 1000) + verse;
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
        home: DailyVerseScreen(
          randomSectionLoader: () async => const CommentaryEntry(
            refsInBlock: ['6.28ab'],
            commentaryText: 'test',
          ),
          verseIndexForRef: indexForRef,
          verseTextForIndex: (_) => 'line 1\nline 2',
          minLinesForSection: 4,
          onResolvedRefsForTest: (refs) => resolvedRefs = refs,
        ),
      ),
    );
    await waitForDailyLoad(tester);

    expect(resolvedRefs, isNotNull);
    final chapters = resolvedRefs!
        .map((r) => RegExp(r'^(\d+)\.').firstMatch(r)?.group(1))
        .whereType<String>()
        .toSet();
    expect(chapters, equals({'6'}));
  });
}
