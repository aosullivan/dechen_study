/// Widget tests for BcvReadScreen, especially key-down navigation.
///
/// Run: flutter test test/bcv_read_screen_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:dechen_study/screens/landing/bcv_read_screen.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_breadcrumb_bar.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_chapters_panel.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_mobile_nav_bar.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_section_slider.dart';
import 'package:dechen_study/services/bcv_verse_service.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';
import 'package:dechen_study/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int verseIndex237;
  late int verseIndex649;
  late int firstLeafVerseIndex;
  late int lastLeafVerseIndex;
  late List<({String path, String title, int depth})> leafOrdered;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 500);
  });

  setUpAll(() async {
    final verseService = BcvVerseService.instance;
    final hierarchyService = VerseHierarchyService.instance;
    await verseService.getChapters();
    await hierarchyService.getHierarchyForVerse('1.1');
    verseIndex237 = verseService.getIndexForRef('2.37') ?? -1;
    verseIndex649 = verseService.getIndexForRef('6.49') ?? -1;
    leafOrdered = hierarchyService.getLeafSectionsByVerseOrderSync();
    firstLeafVerseIndex = -1;
    for (final s in leafOrdered) {
      final ref = hierarchyService.getFirstVerseForSectionSync(s.path);
      final idx =
          ref == null ? null : verseService.getIndexForRefWithFallback(ref);
      if (idx != null) {
        firstLeafVerseIndex = idx;
        break;
      }
    }
    lastLeafVerseIndex = -1;
    for (final s in leafOrdered.reversed) {
      final ref = hierarchyService.getFirstVerseForSectionSync(s.path);
      final idx =
          ref == null ? null : verseService.getIndexForRefWithFallback(ref);
      if (idx != null) {
        lastLeafVerseIndex = idx;
        break;
      }
    }
    expect(verseIndex237, greaterThanOrEqualTo(0),
        reason: 'Verse 2.37 must exist');
    expect(verseIndex649, greaterThanOrEqualTo(0),
        reason: 'Verse 6.49 must exist');
    expect(firstLeafVerseIndex, greaterThanOrEqualTo(0),
        reason: 'First leaf verse must resolve');
    expect(lastLeafVerseIndex, greaterThanOrEqualTo(0),
        reason: 'Last leaf verse must resolve');
  });

  Future<void> pumpBcvReadScreen(
    WidgetTester tester, {
    int? scrollToVerseIndex,
    Size? mediaSize,
    void Function(String sectionPath, String firstVerseRef)?
        onSectionNavigateForTest,
  }) async {
    final screen = BcvReadScreen(
      scrollToVerseIndex: scrollToVerseIndex,
      title: 'Bodhicaryavatara',
      onSectionNavigateForTest: onSectionNavigateForTest,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
        home: mediaSize == null
            ? screen
            : MediaQuery(
                data: MediaQueryData(size: mediaSize),
                child: screen,
              ),
      ),
    );
  }

  Future<void> simulateKeyTap(
      WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.pump();
    await tester.sendKeyUpEvent(key);
    await tester.pump();
  }

  group('BcvReadScreen key-down navigation', () {
    testWidgets('key down from 2.37 navigates to 2.38 then 2.40',
        (WidgetTester tester) async {
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

      expect(find.textContaining('2.40'), findsWidgets);

      // Let programmatic-navigation timers complete (scroll-settle + fallback)
      await tester.pump(const Duration(seconds: 2));
    });

    /// Regression: from 6.49, key down must go to 6.50 (6.50ab), NOT skip to 6.52.
    testWidgets('key down from 6.49 goes to 6.50 not 6.52',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? capturedFirstRef;
      void onNavigate(String path, String firstRef) {
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
      await tester.ensureVisible(
          find.textContaining('It is wrong of you, mind, to be angry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap reader content to give it focus (section panel would nav from wrong section).
      await tester.tap(
          find.textContaining('It is wrong of you, mind, to be angry'),
          warnIfMissed: false);
      await tester.pump();

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        capturedFirstRef,
        isNotNull,
        reason: 'Arrow down should trigger navigation',
      );
      // Next leaf after 6.49 may be 6.50/6.50ab/6.50cd or 6.51 depending on hierarchy; must not skip to 6.52.
      expect(
        capturedFirstRef,
        anyOf(
            equals('6.50ab'), equals('6.50cd'), equals('6.50'), equals('6.51')),
        reason:
            'From 6.49 next must be 6.50/6.50ab/6.50cd/6.51, not 6.52. Got: $capturedFirstRef',
      );
      expect(
        capturedFirstRef,
        isNot(equals('6.52')),
        reason: 'Must not skip from 6.49 to 6.52. Got: $capturedFirstRef',
      );

      // Let programmatic-navigation timers complete
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('key tap dispatches exactly one navigation (keyup ignored)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int navCount = 0;
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex237,
        onSectionNavigateForTest: (_, __) => navCount++,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        navCount,
        1,
        reason: 'One key tap (down+up) should navigate once, never twice.',
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('arrow up at first leaf does not navigate',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int navCount = 0;
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: firstLeafVerseIndex,
        onSectionNavigateForTest: (_, __) => navCount++,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 400));
      expect(navCount, 0, reason: 'At first leaf, ArrowUp should be a no-op');
    });

    testWidgets('arrow down at last leaf does not navigate',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int navCount = 0;
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: lastLeafVerseIndex,
        onSectionNavigateForTest: (_, __) => navCount++,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      expect(navCount, 0, reason: 'At last leaf, ArrowDown should be a no-op');
    });

    testWidgets(
        'section-list auto-scroll does not trigger extra section navigation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int navCount = 0;
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex649,
        onSectionNavigateForTest: (_, __) => navCount++,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(
        find.textContaining('It is wrong of you, mind, to be angry'),
        warnIfMissed: false,
      );
      await tester.pump();

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      expect(navCount, 1, reason: 'First keydown should navigate once');

      // Let section slider auto-scroll/cooldown settle. No extra navigation
      // should happen without another key press.
      await tester.pump(const Duration(seconds: 2));
      expect(
        navCount,
        1,
        reason:
            'Auto-scrolling section list must not trigger another section navigation.',
      );
    });
  });

  group('BcvReadScreen panel defaults by layout', () {
    testWidgets('mobile opens with chapter/section/breadcrumb collapsed',
        (WidgetTester tester) async {
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex237,
        mediaSize: const Size(390, 844),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(BcvMobileNavBar), findsOneWidget);
      expect(find.byType(BcvChaptersPanel), findsNothing);
      expect(find.byType(BcvSectionSlider), findsNothing);
      expect(find.byType(BcvBreadcrumbBar), findsNothing);
    });

    testWidgets(
        'laptop opens with chapter/section/breadcrumb expanded by default',
        (WidgetTester tester) async {
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex237,
        mediaSize: const Size(1200, 800),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(BcvMobileNavBar), findsNothing);
      expect(find.byType(BcvChaptersPanel), findsOneWidget);
      expect(find.byType(BcvSectionSlider), findsOneWidget);
      expect(find.byType(BcvBreadcrumbBar), findsOneWidget);
    });
  });
}
