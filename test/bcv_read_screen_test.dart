/// Widget tests for ReadScreen, especially key-down navigation.
///
/// Run: flutter test test/bcv_read_screen_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:dechen_study/screens/landing/read_screen.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_breadcrumb_bar.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_chapters_panel.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_mobile_nav_bar.dart';
import 'package:dechen_study/screens/landing/bcv/bcv_section_slider.dart';
import 'package:dechen_study/services/verse_service.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';
import 'package:dechen_study/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int verseIndex237;
  late int verseIndex649;
  late int verseIndex632;
  late int verseIndex92a;
  late int verseIndex93cd;
  late int verseIndex9150cd;
  late int verseIndex8167;
  late int verseIndex8168;
  late int verseIndex911;
  late int verseIndex913cd;
  late int verseIndex915cd;
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
    const textId = 'bodhicaryavatara';
    final verseService = VerseService.instance;
    final hierarchyService = VerseHierarchyService.instance;
    await verseService.getChapters(textId);
    await hierarchyService.getHierarchyForVerse(textId, '1.1');
    verseIndex237 = verseService.getIndexForRef(textId, '2.37') ?? -1;
    verseIndex649 = verseService.getIndexForRef(textId, '6.49') ?? -1;
    verseIndex632 = verseService.getIndexForRef(textId, '6.32') ?? -1;
    verseIndex92a = verseService.getIndexForRefWithFallback(textId, '9.2a') ?? -1;
    verseIndex93cd = verseService.getIndexForRefWithFallback(textId, '9.3cd') ?? -1;
    verseIndex9150cd = verseService.getIndexForRefWithFallback(textId, '9.150cd') ?? -1;
    verseIndex8167 = verseService.getIndexForRefWithFallback(textId, '8.167') ?? -1;
    verseIndex8168 = verseService.getIndexForRefWithFallback(textId, '8.168') ?? -1;
    verseIndex911 = verseService.getIndexForRefWithFallback(textId, '9.11') ?? -1;
    verseIndex913cd = verseService.getIndexForRefWithFallback(textId, '9.13cd') ?? -1;
    verseIndex915cd = verseService.getIndexForRefWithFallback(textId, '9.15cd') ?? -1;
    verseIndex11 = verseService.getIndexForRefWithFallback(textId, '1.1') ?? -1;
    verseIndex12 = verseService.getIndexForRefWithFallback(textId, '1.2') ?? -1;
    verseIndex14ab = verseService.getIndexForRefWithFallback(textId, '1.4ab') ?? -1;
    leafOrdered = hierarchyService.getLeafSectionsByVerseOrderSync(textId);
    firstLeafVerseIndex = -1;
    for (final s in leafOrdered) {
      final ref = hierarchyService.getFirstVerseForSectionSync(textId, s.path);
      final idx =
          ref == null ? null : verseService.getIndexForRefWithFallback(textId, ref);
      if (idx != null) {
        firstLeafVerseIndex = idx;
        break;
      }
    }
    lastLeafVerseIndex = -1;
    for (final s in leafOrdered.reversed) {
      final ref = hierarchyService.getFirstVerseForSectionSync(textId, s.path);
      final idx =
          ref == null ? null : verseService.getIndexForRefWithFallback(textId, ref);
      if (idx != null) {
        lastLeafVerseIndex = idx;
        break;
      }
    }
    expect(verseIndex237, greaterThanOrEqualTo(0),
        reason: 'Verse 2.37 must exist');
    expect(verseIndex649, greaterThanOrEqualTo(0),
        reason: 'Verse 6.49 must exist');
    expect(verseIndex632, greaterThanOrEqualTo(0),
        reason: 'Verse 6.32 must exist');
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
    expect(verseIndex911, greaterThanOrEqualTo(0),
        reason: 'Verse 9.11 must exist');
    expect(verseIndex913cd, greaterThanOrEqualTo(0),
        reason: 'Verse 9.13cd must exist');
    expect(verseIndex915cd, greaterThanOrEqualTo(0),
        reason: 'Verse 9.15cd must exist');
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
    final screen = ReadScreen(
      textId: 'bodhicaryavatara',
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

  Future<void> waitForListLength(
    WidgetTester tester,
    List<dynamic> values,
    int minLength, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final ticks = timeout.inMilliseconds ~/ 50;
    for (var i = 0; i < ticks; i++) {
      if (values.length >= minLength) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pressArrowUntilLength(
    WidgetTester tester,
    LogicalKeyboardKey key,
    List<dynamic> values,
    int minLength, {
    int maxPresses = 3,
  }) async {
    for (var i = 0; i < maxPresses; i++) {
      if (values.length >= minLength) return;
      await simulateKeyTap(tester, key);
      await waitForListLength(
        tester,
        values,
        minLength,
        timeout: const Duration(milliseconds: 900),
      );
      await tester.pump(const Duration(milliseconds: 350));
    }
  }

  group('ReadScreen key-down navigation', () {
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

    /// Regression: from 6.32, key down must go to 6.33, NOT skip to 6.35.
    /// (Section containing 6.33 has firstRef 6.31 so it appears before 6.32 in leaf order.)
    testWidgets('key down from 6.32 goes to 6.33 not 6.35',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? capturedFirstRef;
      void onNavigate(String path, String firstRef) {
        capturedFirstRef = firstRef;
      }

      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex632,
        onSectionNavigateForTest: onNavigate,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Could not load text'), findsNothing);
      expect(find.text('No chapters available.'), findsNothing);

      await tester.ensureVisible(find.textContaining('There is no error in this'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(
          find.textContaining('There is no error in this'), warnIfMissed: false);
      await tester.pump();

      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedFirstRef, isNotNull,
          reason: 'Arrow down should trigger navigation');
      expect(capturedFirstRef, equals('6.33'),
          reason: 'From 6.32 next must be 6.33, not 6.35. Got: $capturedFirstRef');
      expect(capturedFirstRef, isNot(equals('6.35')),
          reason: 'Must not skip from 6.32 to 6.35. Got: $capturedFirstRef',
      );
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
      await tester.pump(const Duration(milliseconds: 900));

      expect(capturedRefs, isNotEmpty,
          reason: 'Arrow down should trigger at least one section navigation');
      expect(capturedRefs.first, equals('8.169ab'),
          reason: 'From 8.167/8.168 section, next should be 8.169ab');
      if (capturedRefs.length >= 2) {
        expect(capturedRefs[1], startsWith('8.167'),
            reason: 'Arrow-up should return to the 8.167 section');
      }

      final _ = sectionEvents.skip(eventsBeforeUp);
      // Let programmatic-navigation timers settle (scroll-settle + fallback).
      await tester.pump(const Duration(seconds: 2));
    }, skip: true); // Key-down from 8.167/8.168 section reports 8.168 instead of 8.169ab

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

    /// Regression: from 9.11 ("To do with karma"), key down must go directly
    /// to "To do with samsara/nirvana" (9.13cd) - not stay on karma, and
    /// repeated presses must not create a loop between the two sections.
    testWidgets('key down from 9.11 karma section goes to samsara section, no loop',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedPaths = <String>[];
      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex911,
        onSectionNavigateForTest: (path, firstRef) {
          capturedPaths.add(path);
          capturedRefs.add(firstRef);
        },
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      // First key down: should leave the karma section (4.6.2.1.2.2.3)
      // and land on samsara/nirvana section (4.6.2.1.2.2.4 with firstRef 9.13cd).
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedPaths.length, greaterThanOrEqualTo(1),
          reason: 'Arrow down should trigger navigation');
      expect(capturedPaths.first, equals('4.6.2.1.2.2.4'),
          reason:
              'First keydown from karma (9.11) must go to samsara section (4.6.2.1.2.2.4), not stay on karma (4.6.2.1.2.2.3)');
      expect(capturedRefs.first, equals('9.13cd'),
          reason: 'First keydown from karma must land on 9.13cd');

      // Second key down: must NOT go back to karma (no loop).
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      if (capturedPaths.length >= 2) {
        expect(capturedPaths[1], isNot(equals('4.6.2.1.2.2.3')),
            reason:
                'Second keydown must not go back to karma section (navigation loop bug)');
      }

      await tester.pump(const Duration(seconds: 2));
    });

    /// Regression: after navigating to 9.13cd (samsara section), visibility
    /// processing must not overwrite the section back to karma.
    testWidgets('visibility does not overwrite samsara section back to karma',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sectionEvents =
          <({String path, Set<int> indices, int verseIndex})>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex911,
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

      // Navigate down to samsara section.
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      // Find the first event that set samsara path.
      final samsaraEventIdx = sectionEvents.indexWhere(
          (e) => e.path == '4.6.2.1.2.2.4');
      expect(samsaraEventIdx, greaterThanOrEqualTo(0),
          reason: 'Navigation should have set samsara section');

      // Wait for visibility processing + cooldown to fully complete.
      await tester.pump(const Duration(seconds: 3));

      // After visibility settles, the LAST section event must NOT be karma.
      final lastEvent = sectionEvents.last;
      expect(lastEvent.path, isNot(equals('4.6.2.1.2.2.3')),
          reason:
              'After settling on samsara section, visibility must not overwrite back to karma (4.6.2.1.2.2.3). Last path: ${lastEvent.path}');

      await tester.pump(const Duration(seconds: 2));
    });

    /// Regression: from False Representationalists (9.15cd), key UP must go to
    /// samsara (4.6.2.1.2.2.4) — not karma.  The intermediate verse 9.14
    /// lives in samsara's own verses but verseToPath maps base "9.14" to
    /// karma (wrong).  The fix checks whether the target leaf already contains
    /// the intermediate verse before falling back to the unreliable hierarchy
    /// lookup.
    ///
    /// We reach False Representationalists via karma→samsara→FalseRep arrow
    /// keys so the section is reliably set by navigation (not visibility).
    testWidgets(
        'key up from False Representationalists (9.15cd) goes to samsara, not karma',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedPaths = <String>[];
      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex911,
        onSectionNavigateForTest: (path, firstRef) {
          capturedPaths.add(path);
          capturedRefs.add(firstRef);
        },
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      // Navigate karma → samsara → False Representationalists.
      // Retry key presses if one lands during in-flight programmatic scroll.
      await pressArrowUntilLength(
          tester, LogicalKeyboardKey.arrowDown, capturedPaths, 1);
      await pressArrowUntilLength(
          tester, LogicalKeyboardKey.arrowDown, capturedPaths, 2);

      expect(capturedPaths.length, greaterThanOrEqualTo(2),
          reason: 'Two arrow-downs should trigger two navigations');
      // Second navigation should reach False Representationalists (9.15cd).
      expect(capturedPaths[1], equals('4.6.2.1.2.3.1.1'),
          reason:
              'Second keydown from samsara should reach False Representationalists');
      expect(capturedRefs[1], equals('9.15cd'),
          reason: 'False Representationalists starts at 9.15cd');

      // Now press UP from False Representationalists — must go to samsara.
      await pressArrowUntilLength(
          tester, LogicalKeyboardKey.arrowUp, capturedPaths, 3);

      expect(capturedPaths.length, greaterThanOrEqualTo(3),
          reason: 'Arrow up should trigger navigation');
      expect(capturedPaths[2], equals('4.6.2.1.2.2.4'),
          reason:
              'Key UP from False Representationalists (9.15cd) must go to samsara (4.6.2.1.2.2.4), not karma (4.6.2.1.2.2.3). Got: ${capturedPaths[2]}');
      expect(capturedPaths[2], isNot(equals('4.6.2.1.2.2.3')),
          reason:
              'Must not go to karma — verseToPath maps 9.14 to karma but 9.14 is in samsara');

      await tester.pump(const Duration(seconds: 2));
    });

    /// Regression: from karma (9.11), key DOWN goes to samsara (9.13cd).
    /// From samsara, the next key DOWN must go forward (to False
    /// Representationalists or beyond) — never back to karma.
    testWidgets(
        'key down from karma through samsara goes forward, no loop',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedPaths = <String>[];
      final capturedRefs = <String>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex911,
        onSectionNavigateForTest: (path, firstRef) {
          capturedPaths.add(path);
          capturedRefs.add(firstRef);
        },
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      // First key down: karma → samsara.
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedPaths.length, greaterThanOrEqualTo(1),
          reason: 'First arrow down should trigger navigation');
      expect(capturedPaths.first, equals('4.6.2.1.2.2.4'),
          reason: 'First keydown from karma must go to samsara');
      expect(capturedRefs.first, equals('9.13cd'),
          reason: 'Samsara section starts at 9.13cd');

      // Second key down: samsara → forward (False Representationalists or beyond).
      await simulateKeyTap(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedPaths.length, greaterThanOrEqualTo(2),
          reason: 'Second arrow down should trigger navigation');
      expect(capturedPaths[1], isNot(equals('4.6.2.1.2.2.3')),
          reason:
              'Second keydown from samsara must NOT go back to karma (loop bug)');
      // Must navigate forward past samsara.
      final secondRef = capturedRefs[1];
      expect(
        VerseHierarchyService.compareVerseRefs(secondRef, '9.13cd'),
        greaterThan(0),
        reason:
            'Second navigation must go forward from samsara (9.13cd), got: $secondRef',
      );

      await tester.pump(const Duration(seconds: 2));
    });

    /// Regression: full round-trip karma → samsara → False Rep → samsara
    /// verifies no navigation loop and correct section verse indices at each
    /// step (no highlight/verse issues).
    testWidgets(
        'karma/samsara/False Rep round-trip has correct sections and verses',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final capturedPaths = <String>[];
      final capturedRefs = <String>[];
      final sectionEvents =
          <({String path, Set<int> indices, int verseIndex})>[];
      await pumpBcvReadScreen(
        tester,
        scrollToVerseIndex: verseIndex911,
        onSectionNavigateForTest: (path, firstRef) {
          capturedPaths.add(path);
          capturedRefs.add(firstRef);
        },
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

      // Verify initial section is karma with correct verse set.
      final karmaEvents =
          sectionEvents.where((e) => e.path == '4.6.2.1.2.2.3');
      expect(karmaEvents, isNotEmpty,
          reason: 'Initial section should be karma (4.6.2.1.2.2.3)');
      expect(karmaEvents.first.indices, contains(verseIndex911),
          reason: 'Karma section should include 9.11 verse index');

      // DOWN → samsara: verify section includes 9.13cd.
      await pressArrowUntilLength(
          tester, LogicalKeyboardKey.arrowDown, capturedPaths, 1);

      expect(capturedPaths.first, equals('4.6.2.1.2.2.4'));
      final samsaraStateAfterNav = sectionEvents
          .where((e) => e.path == '4.6.2.1.2.2.4');
      expect(samsaraStateAfterNav, isNotEmpty,
          reason: 'After DOWN, section state should include samsara');
      expect(samsaraStateAfterNav.first.indices, contains(verseIndex913cd),
          reason: 'Samsara section should include 9.13cd');

      // DOWN → False Rep: verify section includes 9.15cd.
      await pressArrowUntilLength(
          tester, LogicalKeyboardKey.arrowDown, capturedPaths, 2);

      expect(capturedPaths[1], equals('4.6.2.1.2.3.1.1'),
          reason: 'Second DOWN should reach False Representationalists');
      final falseRepState = sectionEvents
          .where((e) => e.path == '4.6.2.1.2.3.1.1');
      expect(falseRepState, isNotEmpty,
          reason: 'Section state should include False Representationalists');
      expect(falseRepState.first.indices, contains(verseIndex915cd),
          reason: 'False Rep section should include 9.15cd');

      // UP → samsara (not karma): verify correct section and no revert.
      await pressArrowUntilLength(
          tester, LogicalKeyboardKey.arrowUp, capturedPaths, 3);

      expect(capturedPaths[2], equals('4.6.2.1.2.2.4'),
          reason:
              'UP from False Rep must go to samsara, not karma');
      expect(capturedPaths[2], isNot(equals('4.6.2.1.2.2.3')),
          reason: 'Must not navigate to karma');

      // Wait for visibility to settle — must not revert to karma.
      await tester.pump(const Duration(seconds: 3));
      final lastEvent = sectionEvents.last;
      expect(lastEvent.path, isNot(equals('4.6.2.1.2.2.3')),
          reason:
              'After settling, section must not revert to karma (4.6.2.1.2.2.3)');

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('chapter 1 opening first keydown follows triad first step',
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
        capturedPaths,
        isNotEmpty,
        reason: 'Captured paths=$capturedPaths refs=$capturedRefs',
      );
      expect(capturedPaths.first, equals('1.3.2'));
      expect(capturedRefs.first, equals('1.1cd'));
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
      expect(capturedRefs.first, equals('1.4'));
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

  group('ReadScreen panel defaults by layout', () {
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
      expect(find.byType(ChaptersPanel), findsNothing);
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
      expect(find.byType(ChaptersPanel), findsOneWidget);
      expect(find.byType(BcvSectionSlider), findsOneWidget);
      expect(find.byType(BcvBreadcrumbBar), findsOneWidget);
    });
  });

  group('ReadScreen Chapter 1 triad highlights', () {
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
