library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/screens/landing/daily_verse_screen.dart';
import 'package:dechen_study/screens/landing/bcv_read_screen.dart';
import 'package:dechen_study/services/commentary_service.dart';
import 'package:dechen_study/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDaily(
    WidgetTester tester, {
    required List<String> refs,
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
        ),
      ),
    );
  }

  testWidgets('split ref ab renders first-half text (not blank)',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['8.136ab']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 8.136ab'), findsOneWidget);
    expect(find.textContaining('Because it will'), findsWidgets);
    expect(
        find.textContaining('I will give myself up for others'), findsNothing);
  });

  testWidgets('split ref cd renders second-half text',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['8.136cd']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 8.136cd'), findsOneWidget);
    expect(
        find.textContaining('I will give myself up for others'), findsWidgets);
    expect(find.textContaining('Because it will'), findsNothing);
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
    expect(find.text('Verse 7.7a'), findsOneWidget);
    expect(find.textContaining('Because it will'), findsWidgets);
    expect(
      find.textContaining('And pacify the'),
      findsNothing,
    );
    expect(
      find.textContaining('I will give myself up for others'),
      findsNothing,
    );
  });

  testWidgets('split ref bcd renders second-half text',
      (WidgetTester tester) async {
    await pumpDaily(tester, refs: const ['7.7bcd']);
    await tester.pumpAndSettle();

    expect(find.text('Could not load section'), findsNothing);
    expect(find.text('Verse 7.7bcd'), findsOneWidget);
    expect(
      find.textContaining('And pacify the'),
      findsWidgets,
    );
    expect(
      find.textContaining('I will give myself up for others'),
      findsWidgets,
    );
    expect(
      find.textContaining('And embrace others'),
      findsWidgets,
    );
    expect(find.textContaining('Because it will'), findsNothing);
  });
}
