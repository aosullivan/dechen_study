library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:dechen_study/screens/landing/bcv/bcv_verse_text.dart';
import 'package:dechen_study/screens/landing/read_screen.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';
import 'package:dechen_study/services/verse_service.dart';
import 'package:dechen_study/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int verseIndex11;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 500);
  });

  setUpAll(() async {
    const textId = 'bodhicaryavatara';
    await VerseService.instance.getChapters(textId);
    await VerseHierarchyService.instance.getHierarchyForVerse(textId, '1.1');
    verseIndex11 =
        VerseService.instance.getIndexForRefWithFallback(textId, '1.1') ?? -1;
    expect(verseIndex11, greaterThanOrEqualTo(0));
  });

  testWidgets(
      'mobile reader uses full content width for verses (no extra right squeeze)',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
        home: ReadScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
          scrollToVerseIndex: verseIndex11,
        ),
      ),
    );

    final verseFinder = find.byType(BcvVerseText);
    for (var i = 0; i < 80 && verseFinder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Could not load text'), findsNothing);
    expect(verseFinder, findsWidgets);

    final verseWidth = tester.getSize(verseFinder.first).width;
    // 390 viewport - 16 left reader padding - 16 right reader padding - 18+18 verse inset.
    expect(verseWidth, closeTo(322, 1.0));

    // Let startup/visibility timers settle before test teardown.
    await tester.pump(const Duration(seconds: 2));
  });
}
