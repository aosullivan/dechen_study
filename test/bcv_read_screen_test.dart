/// Widget tests for BcvReadScreen, especially key-down navigation.
///
/// Run: flutter test test/bcv_read_screen_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:dechen_study/screens/landing/bcv_read_screen.dart';
import 'package:dechen_study/services/bcv_verse_service.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';
import 'package:dechen_study/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int verseIndex237;
  late int verseIndex649;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 500);
  });

  setUpAll(() async {
    final verseService = BcvVerseService.instance;
    final hierarchyService = VerseHierarchyService.instance;
    await verseService.getChapters();
    await hierarchyService.getHierarchyForVerse('1.1');
    verseIndex237 = verseService.getIndexForRef('2.37') ?? -1;
    verseIndex649 = verseService.getIndexForRef('6.49') ?? -1;
    expect(verseIndex237, greaterThanOrEqualTo(0), reason: 'Verse 2.37 must exist');
    expect(verseIndex649, greaterThanOrEqualTo(0), reason: 'Verse 6.49 must exist');
  });

  Future<void> pumpBcvReadScreen(
    WidgetTester tester, {
    int? scrollToVerseIndex,
    void Function(String sectionPath, String firstVerseRef)? onSectionNavigateForTest,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
        home: BcvReadScreen(
          scrollToVerseIndex: scrollToVerseIndex,
          title: 'Bodhicaryavatara',
          onSectionNavigateForTest: onSectionNavigateForTest,
        ),
      ),
    );
  }

  Future<void> simulateKeyTap(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.pump();
    await tester.sendKeyUpEvent(key);
    await tester.pump();
  }

  group('BcvReadScreen key-down navigation', () {
    testWidgets('key down from 2.37 navigates to 2.38 then 2.40', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpBcvReadScreen(tester, scrollToVerseIndex: verseIndex237);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Could not load text'), findsNothing);
      expect(find.text('No chapters available.'), findsNothing);

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 300));
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('[2.40]'), findsWidgets);

      // Let programmatic-navigation timers complete (scroll-settle + fallback)
      await tester.pump(const Duration(seconds: 2));
    });

    /// Regression: from 6.49, key down must go to 6.50 (6.50ab), NOT skip to 6.52.
    testWidgets('key down from 6.49 goes to 6.50 not 6.52', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? capturedPath;
      String? capturedFirstRef;
      void onNavigate(String path, String firstRef) {
        capturedPath = path;
        capturedFirstRef = firstRef;
      }

      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex649,
        onSectionNavigateForTest: onNavigate,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Could not load text'), findsNothing);
      expect(find.text('No chapters available.'), findsNothing);

      // Ensure 6.49 is scrolled into view so visibility sets _visibleVerseIndex to 6.49.
      await tester.ensureVisible(find.textContaining('It is wrong of you, mind, to be angry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap reader content to give it focus (section panel would nav from wrong section).
      await tester.tap(find.textContaining('It is wrong of you, mind, to be angry'), warnIfMissed: false);
      await tester.pump();

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        capturedFirstRef,
        isNotNull,
        reason: 'Arrow down should trigger navigation',
      );
      expect(
        capturedFirstRef,
        anyOf(equals('6.50ab'), equals('6.50cd'), equals('6.50')),
        reason: 'From 6.49 next must be 6.50/6.50ab/6.50cd, not 6.52. Got: $capturedFirstRef',
      );
      expect(
        capturedFirstRef,
        isNot(equals('6.52')),
        reason: 'Must not skip from 6.49 to 6.52. Got: $capturedFirstRef',
      );

      // Let programmatic-navigation timers complete
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
