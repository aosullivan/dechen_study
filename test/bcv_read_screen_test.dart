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
  late int verseIndex92a;
  late int verseIndex93cd;
  late int verseIndex9150cd;
  late int verseIndex8167;
  late int verseIndex8168;
  late int verseIndex11;
  late int verseIndex12;
  late int verseIndex14ab;
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
    verseIndex92a = verseService.getIndexForRefWithFallback('9.2a') ?? -1;
    verseIndex93cd = verseService.getIndexForRefWithFallback('9.3cd') ?? -1;
    verseIndex9150cd = verseService.getIndexForRefWithFallback('9.150cd') ?? -1;
    verseIndex8167 = verseService.getIndexForRefWithFallback('8.167') ?? -1;
    verseIndex8168 = verseService.getIndexForRefWithFallback('8.168') ?? -1;
    verseIndex11 = verseService.getIndexForRefWithFallback('1.1') ?? -1;
    verseIndex12 = verseService.getIndexForRefWithFallback('1.2') ?? -1;
    verseIndex14ab = verseService.getIndexForRefWithFallback('1.4ab') ?? -1;
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
    expect(verseIndex92a, greaterThanOrEqualTo(0),
        reason: 'Verse 9.2a must exist');
    expect(verseIndex93cd, greaterThanOrEqualTo(0),
        reason: 'Verse 9.3cd must exist');
    expect(verseIndex9150cd, greaterThanOrEqualTo(0),
        reason: 'Verse 9.150cd must exist');
    expect(verseIndex8167, greaterThanOrEqualTo(0),
        reason: 'Verse 8.167 must exist');
    expect(verseIndex8168, greaterThanOrEqualTo(0),
        reason: 'Verse 8.168 must exist');
    expect(verseIndex11, greaterThanOrEqualTo(0),
        reason: 'Verse 1.1 must exist');
    expect(verseIndex12, greaterThanOrEqualTo(0),
        reason: 'Verse 1.2 must exist');
    expect(verseIndex14ab, greaterThanOrEqualTo(0),
        reason: 'Verse 1.4ab must exist');
    expect(firstLeafVerseIndex, greaterThanOrEqualTo(0),
        reason: 'First leaf verse must resolve');
    expect(lastLeafVerseIndex, greaterThanOrEqualTo(0),
        reason: 'Last leaf verse must resolve');
  });

  Future<void> pumpBcvReadScreen(
    WidgetTester tester, {
    int? scrollToVerseIndex,
    String? initialSegmentRef,
    Size? mediaSize,
    void Function(String sectionPath, String firstVerseRef)?
        onSectionNavigateForTest,
    void Function(String sectionPath, Set<int> verseIndices, int verseIndex)?
        onSectionStateForTest,
  }) async {
    final screen = BcvReadScreen(
      scrollToVerseIndex: scrollToVerseIndex,
      initialSegmentRef: initialSegmentRef,
      title: 'Bodhicaryavatara',
      onSectionNavigateForTest: onSectionNavigateForTest,
      onSectionStateForTest: onSectionStateForTest,
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

    testWidgets('resume reading on 8.167 applies section that includes 8.168',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sectionEvents =
          <({String path, Set<int> indices, int verseIndex})>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex8167,
        onSectionStateForTest: (path, indices, verseIndex) {
          sectionEvents.add(
            (
              path: path,
              indices: Set<int>.from(indices),
              verseIndex: verseIndex,
            ),
          );
        },
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      final hasFullSectionFor8167 = sectionEvents.any((e) =>
          e.verseIndex == verseIndex8167 &&
          e.indices.contains(verseIndex8167) &&
          e.indices.contains(verseIndex8168));
      expect(hasFullSectionFor8167, isTrue,
          reason:
              'Resume reading should apply the full 8.167/8.168 section, not only verse 8.167');
    });

    testWidgets('from resume 8.167, down then up restores 8.167/8.168 section',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedRefs = <String>[];
      final sectionEvents =
          <({String path, Set<int> indices, int verseIndex})>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex8167,
        onSectionNavigateForTest: (_, firstRef) => capturedRefs.add(firstRef),
        onSectionStateForTest: (path, indices, verseIndex) {
          sectionEvents.add(
            (
              path: path,
              indices: Set<int>.from(indices),
              verseIndex: verseIndex,
            ),
          );
        },
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      final eventsBeforeUp = sectionEvents.length;

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedRefs.length, greaterThanOrEqualTo(2),
          reason: 'Down and up should each trigger one section navigation');
      expect(capturedRefs[0], equals('8.169ab'),
          reason: 'From 8.167/8.168 section, next should be 8.169ab');
      expect(capturedRefs[1], startsWith('8.167'),
          reason: 'Arrow-up should return to the 8.167 section');

      final postUpEvents = sectionEvents.skip(eventsBeforeUp);
      final restored = postUpEvents.any((e) =>
          e.verseIndex == verseIndex8167 &&
          e.indices.contains(verseIndex8167) &&
          e.indices.contains(verseIndex8168));
      expect(restored, isTrue,
          reason:
              'After arrow-up, section highlight must be restored to include both 8.167 and 8.168');
      // Let programmatic-navigation timers settle (scroll-settle + fallback).
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
        'from 9.2a, first key down lands on 9.2bcd (parent-owned section)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex92a,
        onSectionNavigateForTest: (_, firstRef) => capturedRefs.add(firstRef),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      expect(capturedRefs.length, greaterThanOrEqualTo(1),
          reason: 'Arrow down should trigger a navigation callback');
      expect(capturedRefs.first, equals('9.2bcd'),
          reason: 'First keydown from 9.2a must land on parent-owned 9.2bcd');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
        'from 9.3cd section, first key down lands on 9.4d (not grouped with c)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex93cd,
        initialSegmentRef: '9.3cd',
        onSectionNavigateForTest: (_, firstRef) => capturedRefs.add(firstRef),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedRefs.length, greaterThanOrEqualTo(1),
          reason: 'Arrow down should trigger a navigation callback');
      expect(capturedRefs.first, equals('9.4d'),
          reason:
              'From the 9.3cd/9.4abc section, next section must be 9.4d only');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('from 9.150cd, first key down lands on 9.151',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex9150cd,
        initialSegmentRef: '9.150cd',
        onSectionNavigateForTest: (_, firstRef) => capturedRefs.add(firstRef),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedRefs.length, greaterThanOrEqualTo(1),
          reason: 'Arrow down should trigger a navigation callback');
      expect(capturedRefs.first, equals('9.151'),
          reason: 'From 9.150cd, next section must be the 9.151/9.152 section');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('chapter 1 opening keydown follows triad sequence for 1.1-1.3',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedPaths = <String>[];
      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex11,
        initialSegmentRef: '1.1ab',
        onSectionNavigateForTest: (path, firstRef) {
          capturedPaths.add(path);
          capturedRefs.add(firstRef);
        },
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        capturedPaths.length,
        greaterThanOrEqualTo(2),
        reason: 'Captured paths=$capturedPaths refs=$capturedRefs',
      );
      expect(capturedPaths[0], equals('1.3.2'));
      expect(capturedRefs[0], equals('1.1cd'));
      expect(capturedPaths[1], equals('1.2.3'));
      expect(capturedRefs[1], equals('1.2'));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('chapter 1 discarding keydown moves directly to 1.4',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedPaths = <String>[];
      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex12,
        initialSegmentRef: '1.2',
        onSectionNavigateForTest: (path, firstRef) {
          capturedPaths.add(path);
          capturedRefs.add(firstRef);
        },
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedPaths.length, greaterThanOrEqualTo(1));
      expect(capturedPaths.first, equals('2.1'));
      expect(capturedRefs.first, equals('1.4ab'));
      expect(capturedRefs, isNot(contains('1.3cd')));
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
        'no-op boundary key does not consume next opposite-direction key press',
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

      // First key is a no-op at the top boundary.
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 10));
      expect(navCount, 0);

      // Immediate opposite key should navigate on first press.
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        navCount,
        1,
        reason:
            'A no-op arrow key should not consume debounce and force double-press on next valid move.',
      );
      await tester.pump(const Duration(seconds: 2));
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

  group('BcvReadScreen Chapter 1 triad highlights', () {
    Future<void> pumpChapterOneSegment(
      WidgetTester tester, {
      required int verseIndex,
      required String segmentRef,
    }) async {
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex,
        initialSegmentRef: segmentRef,
        mediaSize: const Size(1200, 800),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('1.1ab maps to homage stop', (WidgetTester tester) async {
      await pumpChapterOneSegment(
        tester,
        verseIndex: verseIndex11,
        segmentRef: '1.1ab',
      );
      final slider =
          tester.widget<BcvSectionSlider>(find.byType(BcvSectionSlider));
      expect(slider.currentPath, equals('1.3.1'));
      expect(slider.additionalHighlightedPaths, isEmpty);
    });

    testWidgets('base 1.1 defaults to homage stop',
        (WidgetTester tester) async {
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex11,
        mediaSize: const Size(1200, 800),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
      final slider =
          tester.widget<BcvSectionSlider>(find.byType(BcvSectionSlider));
      expect(slider.currentPath, equals('1.3.1'));
      expect(slider.additionalHighlightedPaths, isEmpty);
    });

    testWidgets('1.1cd maps to commitment stop', (WidgetTester tester) async {
      await pumpChapterOneSegment(
        tester,
        verseIndex: verseIndex11,
        segmentRef: '1.1cd',
      );
      final slider =
          tester.widget<BcvSectionSlider>(find.byType(BcvSectionSlider));
      expect(slider.currentPath, equals('1.3.2'));
      expect(slider.additionalHighlightedPaths, isEmpty);
    });

    testWidgets('opening section overview defaults to simplified structure',
        (WidgetTester tester) async {
      await pumpChapterOneSegment(
        tester,
        verseIndex: verseIndex11,
        segmentRef: '1.1cd',
      );
      final slider =
          tester.widget<BcvSectionSlider>(find.byType(BcvSectionSlider));
      final paths = slider.flatSections.map((s) => s.path).toSet();
      final roots = slider.flatSections.where((s) => s.path == '1').length;
      expect(paths, contains('1.3.1'));
      expect(paths, contains('1.3.2'));
      expect(paths, contains('1.2.3'));
      expect(paths, contains('1.4'));
      expect(roots, 1);
      expect(slider.expandablePaths, isEmpty);
      expect(slider.nonNavigablePaths, contains('1.4'));
      expect(paths, isNot(contains('1.1.1')));
      expect(paths, isNot(contains('1.3.2.1')));
      expect(paths, isNot(contains('1.3.3.1')));
      expect(paths, isNot(contains('1.4.1')));
      expect(find.byKey(const Key('section_expand_1.3.2')), findsNothing);
      expect(
        slider.flatSections.where((s) => s.path == '1.3.1').first.title,
        equals('Homage and praise'),
      );
    });

    testWidgets('1.2 maps to discarding stop', (WidgetTester tester) async {
      await pumpChapterOneSegment(
        tester,
        verseIndex: verseIndex12,
        segmentRef: '1.2',
      );
      final slider =
          tester.widget<BcvSectionSlider>(find.byType(BcvSectionSlider));
      expect(slider.currentPath, equals('1.2.3'));
      expect(slider.additionalHighlightedPaths, isEmpty);
    });

    testWidgets('1.2abc still maps to discarding stop in simplified overview',
        (WidgetTester tester) async {
      await pumpChapterOneSegment(
        tester,
        verseIndex: verseIndex12,
        segmentRef: '1.2abc',
      );
      final slider =
          tester.widget<BcvSectionSlider>(find.byType(BcvSectionSlider));
      expect(slider.currentPath, equals('1.2.3'));
      final paths = slider.flatSections.map((s) => s.path).toSet();
      expect(paths, isNot(contains('1.3.3.1')));
      expect(paths, isNot(contains('1.3.3.2')));
      expect(paths, isNot(contains('1.3.3.3')));
    });

    testWidgets('1.4ab highlights real section, not implicit section 1.4',
        (WidgetTester tester) async {
      await pumpChapterOneSegment(
        tester,
        verseIndex: verseIndex14ab,
        segmentRef: '1.4ab',
      );
      final slider =
          tester.widget<BcvSectionSlider>(find.byType(BcvSectionSlider));
      expect(slider.currentPath, equals('2.1'));
      expect(slider.currentPath, isNot(equals('1.4')));
      expect(slider.nonNavigablePaths, contains('1.4'));
    });
  });
}
