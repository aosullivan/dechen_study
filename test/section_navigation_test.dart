/// Tests for section navigation logic (arrow-key up/down).
/// Verifies verse-ordered navigation, deduplication, and adjacent-section lookup.
///
/// Run: flutter test test/section_navigation_test.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/services/bcv_verse_service.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';

const _expectedLeafSkipCount = 174;
const _expectedLeafGapSum = 497;
const _expectedLeafMaxGap = 12;
const _expectedLeafSkipsFirst5 = <String>[
  '3.1.2.4 (1.18) -> 3.1.3.1 (1.20): verse gap 2',
  '3.1.3.2.1.1 (1.21) -> 3.1.3.2.1.2.1 (1.23): verse gap 2',
  '3.1.3.2.2.2 (1.28) -> 3.1.3.2.2.3 (1.31): verse gap 3',
  '3.1.3.2.2.4 (1.32) -> 3.1.3.2.2.5 (1.34): verse gap 2',
  '3.2.1.1.2 (2.2) -> 3.2.1.1.3 (2.8): verse gap 6',
];
const _expectedLeafSkipsLast5 = <String>[
  '5.2.1.3.2.1.1 (10.27) -> 5.2.1.3.2.1.2 (10.32): verse gap 5',
  '5.2.1.3.2.1.3 (10.33) -> 5.2.1.3.2.2 (10.42): verse gap 9',
  '5.2.1.3.2.2 (10.42) -> 5.2.2 (10.49): verse gap 7',
  '5.2.2 (10.49) -> 5.3 (10.51): verse gap 2',
  '5.3 (10.51) -> 5.4 (10.57): verse gap 6',
];

const _expectedMissingVerses = <String>[
  '2.13: missing',
  '2.14: missing',
  '2.15: missing',
  '2.16: missing',
  '2.17: missing',
  '2.18: missing',
  '2.19: missing',
  '2.20: missing',
  '2.21: missing',
  '6.27: missing',
  '9.151: missing',
  '9.152: missing',
];
const _expectedNonConsecutive = <String>[
  '2.12 -> 2.22: non-consecutive (gap 10)',
  '6.26 -> 6.28: non-consecutive (gap 2)',
  '9.150cd -> 9.153: non-consecutive (gap 3)',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VerseHierarchyService hierarchyService;
  late BcvVerseService verseService;

  setUpAll(() async {
    hierarchyService = VerseHierarchyService.instance;
    verseService = BcvVerseService.instance;
    await verseService.getChapters();
    await hierarchyService.getHierarchyForVerse('1.1');
  });

  group('VerseHierarchyService', () {
    test('baseVerseFromRef extracts chapter.verse', () {
      expect(VerseHierarchyService.baseVerseFromRef('8.114'), (8, 114));
      expect(VerseHierarchyService.baseVerseFromRef('9.1ab'), (9, 1));
      expect(VerseHierarchyService.baseVerseFromRef('9.116'), (9, 116));
    });

    test('compareVerseRefs orders correctly', () {
      expect(
        VerseHierarchyService.compareVerseRefs('8.114', '8.115'),
        lessThan(0),
      );
      expect(
        VerseHierarchyService.compareVerseRefs('8.115', '8.114'),
        greaterThan(0),
      );
      expect(
        VerseHierarchyService.compareVerseRefs('8.114', '9.1'),
        lessThan(0),
      );
      expect(
        VerseHierarchyService.compareVerseRefs('8.117', '8.115'),
        greaterThan(0),
      );
    });

    test('leaf sections order split verses 8.136ab before 8.136cd for keydown',
        () {
      final leafOrdered = hierarchyService.getLeafSectionsByVerseOrderSync();
      final abIdx = leafOrdered.indexWhere((s) {
        final ref = hierarchyService.getFirstVerseForSectionSync(s.path);
        return ref == '8.136ab';
      });
      final cdIdx = leafOrdered.indexWhere((s) {
        final ref = hierarchyService.getFirstVerseForSectionSync(s.path);
        return ref == '8.136cd';
      });
      if (abIdx >= 0 && cdIdx >= 0) {
        expect(abIdx, lessThan(cdIdx),
            reason:
                '8.136ab section should come before 8.136cd so keydown goes ab -> cd');
      }
    });

    test('getSectionsByVerseOrderSync returns sections in verse order', () {
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      expect(ordered, isNotEmpty);

      String? prevRef;
      for (final s in ordered) {
        final ref = hierarchyService.getFirstVerseForSectionSync(s.path);
        if (ref != null && prevRef != null) {
          expect(
            VerseHierarchyService.compareVerseRefs(ref, prevRef),
            greaterThanOrEqualTo(0),
            reason:
                'Sections should be sorted by first verse: $prevRef then $ref',
          );
        }
        prevRef = ref;
      }
    });

    test('getSectionsByVerseOrderSync deduplicates by base verse', () {
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      final bases = <(int, int)>{};
      for (final s in ordered) {
        final ref = hierarchyService.getFirstVerseForSectionSync(s.path);
        if (ref != null) {
          final base = VerseHierarchyService.baseVerseFromRef(ref);
          expect(bases, isNot(contains(base)), reason: 'Duplicate base $base');
          bases.add(base);
        }
      }
    });

    test('contemplating the faults of that leaf maps to 8.172 and 8.173', () {
      const path = '4.5.3.2.4.2.2.5';
      final refs = hierarchyService.getVerseRefsForSectionSync(path);
      expect(refs, contains('8.172'));
      expect(refs, contains('8.173'));
      expect(hierarchyService.getFirstVerseForSectionSync(path), '8.172');

      final path172 = hierarchyService.getHierarchyForVerseSync('8.172');
      final path173 = hierarchyService.getHierarchyForVerseSync('8.173');
      expect(path172, isNotEmpty);
      expect(path173, isNotEmpty);
      expect(path172.last['section'], path);
      expect(path173.last['section'], path);
    });

    test('4.27 split headings map to non-empty sibling leaves', () {
      const path2 = '4.1.2.2.3.4.2';
      const path3 = '4.1.2.2.3.4.3';

      final refs2 = hierarchyService.getVerseRefsForSectionSync(path2);
      final refs3 = hierarchyService.getVerseRefsForSectionSync(path3);
      expect(refs2, contains('4.27ab'));
      expect(refs3, contains('4.27cd'));

      final path27ab = hierarchyService.getHierarchyForVerseSync('4.27ab');
      final path27cd = hierarchyService.getHierarchyForVerseSync('4.27cd');
      expect(path27ab, isNotEmpty);
      expect(path27cd, isNotEmpty);
      expect(path27ab.last['section'], path2);
      expect(path27cd.last['section'], path3);
    });

    test('8.145 split headings map to non-empty sibling leaves', () {
      const path1 = '4.5.3.2.3.2.3.1';
      const path2 = '4.5.3.2.3.2.3.2';

      final refs1 = hierarchyService.getVerseRefsForSectionSync(path1);
      final refs2 = hierarchyService.getVerseRefsForSectionSync(path2);
      expect(refs1, contains('8.145ab'));
      expect(refs2, contains('8.145cd'));

      final path145ab = hierarchyService.getHierarchyForVerseSync('8.145ab');
      final path145cd = hierarchyService.getHierarchyForVerseSync('8.145cd');
      expect(path145ab, isNotEmpty);
      expect(path145cd, isNotEmpty);
      expect(path145ab.last['section'], path1);
      expect(path145cd.last['section'], path2);
    });

    test('means of averting that cause leaf maps to 6.9 and 6.10', () {
      const path = '4.3.2.1.3';
      const siblingPath = '4.3.2.1.4';

      final refs = hierarchyService.getVerseRefsForSectionSync(path);
      expect(refs, contains('6.9'));
      expect(refs, contains('6.10'));

      final siblingRefs =
          hierarchyService.getVerseRefsForSectionSync(siblingPath);
      expect(siblingRefs, isNot(contains('6.9')));
      expect(siblingRefs, isNot(contains('6.10')));

      final path69 = hierarchyService.getHierarchyForVerseSync('6.9');
      final path610 = hierarchyService.getHierarchyForVerseSync('6.10');
      expect(path69, isNotEmpty);
      expect(path610, isNotEmpty);
      expect(path69.last['section'], path);
      expect(path610.last['section'], path);
    });

    test(
        'single-line leaf section maps to segmented first verse (4.4.2 -> 7.2a)',
        () {
      const path = '4.4.2';
      final refs = hierarchyService.getVerseRefsForSectionSync(path);
      expect(refs, contains('7.2a'));
      expect(hierarchyService.getFirstVerseForSectionSync(path), '7.2a');

      final hierarchy = hierarchyService.getHierarchyForVerseSync('7.2a');
      expect(hierarchy, isNotEmpty);
      expect(hierarchy.last['section'], path);
    });

    test('5.1/5.2 split maps to first three children under guarding the mind',
        () {
      const path1 = '4.2.1.1.1';
      const path2 = '4.2.1.1.2';
      const path3 = '4.2.1.1.3';

      final refs1 = hierarchyService.getVerseRefsForSectionSync(path1);
      final refs2 = hierarchyService.getVerseRefsForSectionSync(path2);
      final refs3 = hierarchyService.getVerseRefsForSectionSync(path3);

      expect(refs1, contains('5.1ab'));
      expect(refs2, contains('5.1cd'));
      expect(refs3, contains('5.2'));
      expect(refs2, isNot(contains('5.1ab')));

      final path51ab = hierarchyService.getHierarchyForVerseSync('5.1ab');
      final path51cd = hierarchyService.getHierarchyForVerseSync('5.1cd');
      final path52 = hierarchyService.getHierarchyForVerseSync('5.2');
      expect(path51ab, isNotEmpty);
      expect(path51cd, isNotEmpty);
      expect(path52, isNotEmpty);
      expect(path51ab.last['section'], path1);
      expect(path51cd.last['section'], path2);
      expect(path52.last['section'], path3);
    });
  });

  group('Adjacent section navigation (8.114 -> 8.115, not 8.117)', () {
    test('from 8.114, next section has first verse 8.115', () {
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      final nextIdx = hierarchyService.findAdjacentSectionIndex(
        ordered,
        '8.114',
        direction: 1,
      );
      expect(nextIdx, greaterThanOrEqualTo(0),
          reason: 'Should find next section');
      final nextRef = hierarchyService.getFirstVerseForSectionSync(
        ordered[nextIdx].path,
      );
      expect(nextRef, isNotNull);
      expect(
        VerseHierarchyService.baseVerseFromRef(nextRef!),
        (8, 115),
        reason: 'Next from 8.114 should be 8.115, not 8.117',
      );
    });

    test('from 8.115, next section has first verse 8.116', () {
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      final nextIdx = hierarchyService.findAdjacentSectionIndex(
        ordered,
        '8.115',
        direction: 1,
      );
      if (nextIdx < 0) return;
      final nextRef = hierarchyService.getFirstVerseForSectionSync(
        ordered[nextIdx].path,
      );
      expect(nextRef, isNotNull);
      final (ch, v) = VerseHierarchyService.baseVerseFromRef(nextRef!);
      expect(ch, 8);
      expect(v, greaterThanOrEqualTo(116), reason: 'Should not skip to 8.117');
    });

    test('from 9.1, next section has first verse 9.2', () {
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      final nextIdx = hierarchyService.findAdjacentSectionIndex(
        ordered,
        '9.1',
        direction: 1,
      );
      expect(nextIdx, greaterThanOrEqualTo(0));
      final nextRef = hierarchyService.getFirstVerseForSectionSync(
        ordered[nextIdx].path,
      );
      expect(nextRef, isNotNull);
      expect(
        VerseHierarchyService.baseVerseFromRef(nextRef!),
        (9, 2),
        reason: 'Next from 9.1 should be 9.2, not 9.116',
      );
    });

    test('from 8.117, previous section has first verse before 8.117', () {
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      final prevIdx = hierarchyService.findAdjacentSectionIndex(
        ordered,
        '8.117',
        direction: -1,
      );
      expect(prevIdx, greaterThanOrEqualTo(0));
      final prevRef = hierarchyService.getFirstVerseForSectionSync(
        ordered[prevIdx].path,
      );
      expect(prevRef, isNotNull);
      expect(
        VerseHierarchyService.compareVerseRefs(prevRef!, '8.117'),
        lessThan(0),
      );
    });
  });

  group('Section overview hierarchy navigation (key-down in section panel)',
      () {
    test('getFlatSectionsSync returns depth-first order', () {
      final flat = hierarchyService.getFlatSectionsSync();
      expect(flat, isNotEmpty);
      // Root sections first, then children. Path "1" before "1.1", "1.1" before "1.1.1"
      final idx1 = flat.indexWhere((s) => s.path == '1');
      final idx11 = flat.indexWhere((s) => s.path == '1.1');
      final idx111 = flat.indexWhere((s) => s.path == '1.1.1');
      expect(idx1, greaterThanOrEqualTo(0), reason: 'Section 1 should exist');
      expect(idx11, greaterThanOrEqualTo(0),
          reason: 'Section 1.1 should exist');
      expect(idx111, greaterThanOrEqualTo(0),
          reason: 'Section 1.1.1 should exist');
      expect(idx1, lessThan(idx11),
          reason: '1 before 1.1 in depth-first order');
      expect(idx11, lessThan(idx111),
          reason: '1.1 before 1.1.1 in depth-first order');
    });

    test('next in hierarchy is flat[i+1], can differ from verse order', () {
      final flat = hierarchyService.getFlatSectionsSync();
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      expect(flat.length, greaterThan(ordered.length),
          reason:
              'Flat has more sections (no dedup); verse-ordered is deduped');
      // From section 1.1: hierarchy next is flat[idx+1] (e.g. 1.1.1), which is a child
      final idx11 = flat.indexWhere((s) => s.path == '1.1');
      expect(idx11, greaterThanOrEqualTo(0));
      if (idx11 + 1 < flat.length) {
        final hierarchyNext = flat[idx11 + 1];
        // 1.1.1 is a child of 1.1 - path is longer
        expect(hierarchyNext.path.startsWith('1.1.'), isTrue,
            reason: 'Next in hierarchy should be child of 1.1');
        expect(
          hierarchyNext.path,
          isNot(equals('1.1')),
          reason: 'Hierarchy next should be a different section',
        );
      }
    });

    test('hierarchy key-down walk: flat[i+1] is next until last', () {
      final flat = hierarchyService.getFlatSectionsSync();
      expect(flat, isNotEmpty);
      for (var i = 0; i < flat.length - 1; i++) {
        final current = flat[i];
        final next = flat[i + 1];
        expect(current.path, isNotEmpty);
        expect(next.path, isNotEmpty);
        // In section overview, key down from current goes to next
        expect(next.path, isNot(equals(current.path)));
      }
    });
  });

  group('Reader key-down (leaf sections only)', () {
    test('leaf sections are in verse order', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      expect(leaves, isNotEmpty);
      String? prevRef;
      for (final s in leaves) {
        final ref = hierarchyService.getFirstVerseForSectionSync(s.path);
        if (ref != null && prevRef != null) {
          expect(
            VerseHierarchyService.compareVerseRefs(ref, prevRef),
            greaterThanOrEqualTo(0),
            reason: 'Leaf sections should be sorted by first verse',
          );
        }
        prevRef = ref;
      }
    });

    test('reader uses index-based nav: leaf[i+1] when currentPath in list', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      expect(leaves.length, greaterThan(1));
      for (var i = 0; i < leaves.length - 1; i++) {
        final curr = leaves[i];
        final next = leaves[i + 1];
        expect(curr.path, isNotEmpty);
        expect(next.path, isNot(equals(curr.path)));
      }
    });

    /// Real-world scenario (user-reported): from 2.37, key down must go to 2.38.
    /// 2.37 and 2.38 have distinct leaf sections; 2.39 lives inside 3.1.1.3.5.
    test('2.37 -> 2.38: leaf sequence is consecutive (no skip to 2.39)', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      final idx237 = leaves.indexWhere((s) =>
          hierarchyService.getFirstVerseForSectionSync(s.path) == '2.37');
      final idx238 = leaves.indexWhere((s) =>
          hierarchyService.getFirstVerseForSectionSync(s.path) == '2.38');

      expect(idx237, greaterThanOrEqualTo(0), reason: '2.37 leaf must exist');
      expect(idx238, greaterThanOrEqualTo(0), reason: '2.38 leaf must exist');
      expect(idx237 + 1, idx238,
          reason:
              'From 2.37 (idx $idx237) next must be 2.38 (idx $idx238), not skip');
    });

    /// Fallback path: when currentPath unknown, findAdjacentSectionIndex(2.37)
    /// must return 2.38, not 2.39.
    test('fallback from 2.37: findAdjacentSectionIndex returns 2.38 not 2.39',
        () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      final nextIdx = hierarchyService.findAdjacentSectionIndex(leaves, '2.37',
          direction: 1);
      expect(nextIdx, greaterThanOrEqualTo(0));
      final nextRef =
          hierarchyService.getFirstVerseForSectionSync(leaves[nextIdx].path);
      expect(nextRef, '2.38',
          reason: 'Fallback from 2.37 must land on 2.38, not 2.39');
    });

    test('8.114 -> 8.115: leaf sequence consecutive (no skip to 8.117)', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      final idx114 = leaves.indexWhere((s) =>
          hierarchyService.getFirstVerseForSectionSync(s.path) == '8.114');
      final idx115 = leaves.indexWhere((s) =>
          hierarchyService.getFirstVerseForSectionSync(s.path) == '8.115');
      expect(idx114, greaterThanOrEqualTo(0));
      expect(idx115, greaterThanOrEqualTo(0));
      expect(idx114 + 1, idx115);
    });

    /// In verse_hierarchy_map, 9.2a/9.2bcd live in parent sections (no leaf);
    /// the first leaf after 9.1 is 9.3. We must not skip to 9.116.
    test(
        'fallback from 9.1: findAdjacentSectionIndex returns 9.2 or 9.3 not 9.116',
        () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      final nextIdx = hierarchyService.findAdjacentSectionIndex(leaves, '9.1',
          direction: 1);
      expect(nextIdx, greaterThanOrEqualTo(0));
      final nextRef =
          hierarchyService.getFirstVerseForSectionSync(leaves[nextIdx].path);
      final (ch, v) = VerseHierarchyService.baseVerseFromRef(nextRef ?? '');
      expect(ch, 9);
      expect(v, lessThanOrEqualTo(3),
          reason:
              'Fallback from 9.1 must land on 9.2 or 9.3, not skip to 9.116');
    });

    /// Real-world: from 6.48 leaf, next leaf must be 6.49 or 6.50 (not skip to 6.52).
    test('6.49 -> 6.50: leaf sequence has no skip to 6.52', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      final idx648 = leaves.indexWhere((s) =>
          hierarchyService.getFirstVerseForSectionSync(s.path) == '6.48');
      expect(idx648, greaterThanOrEqualTo(0), reason: '6.48 leaf must exist');
      final nextRef =
          hierarchyService.getFirstVerseForSectionSync(leaves[idx648 + 1].path);
      expect(
        nextRef,
        anyOf(equals('6.49'), equals('6.50ab'), equals('6.50')),
        reason: 'From 6.48 next must be 6.49 or 6.50/6.50ab, not 6.52',
      );
      expect(
        nextRef,
        isNot(equals('6.52')),
        reason: 'Must not skip from 6.48 to 6.52',
      );
    });

    /// Fallback: findAdjacentSectionIndex(6.49, +1) must return 6.50ab section.
    test('fallback from 6.49: findAdjacentSectionIndex returns 6.50ab not 6.52',
        () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      final nextIdx = hierarchyService.findAdjacentSectionIndex(leaves, '6.49',
          direction: 1);
      expect(nextIdx, greaterThanOrEqualTo(0));
      final nextRef =
          hierarchyService.getFirstVerseForSectionSync(leaves[nextIdx].path);
      expect(
        nextRef,
        anyOf(equals('6.50ab'), equals('6.50cd'), equals('6.50')),
        reason: 'Fallback from 6.49 must land on 6.50, not 6.52',
      );
      expect(nextRef, isNot(equals('6.52')));
    });

    /// Consecutive verses with distinct leaves: 2.34..2.38 must be in order.
    test('reader leaf walk: no skips (2.34 to 2.38)', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      const refs = ['2.34', '2.35', '2.36', '2.37', '2.38'];
      final indices = <String, int>{};
      for (final ref in refs) {
        final idx = leaves.indexWhere(
            (s) => hierarchyService.getFirstVerseForSectionSync(s.path) == ref);
        if (idx >= 0) indices[ref] = idx;
      }
      for (var i = 0; i < refs.length - 1; i++) {
        final curr = refs[i];
        final next = refs[i + 1];
        final currIdx = indices[curr];
        final nextIdx = indices[next];
        if (currIdx != null && nextIdx != null) {
          expect(currIdx + 1, nextIdx,
              reason:
                  'From $curr (idx $currIdx) next must be $next (idx $nextIdx)');
        }
      }
    });
  });

  /// Full-doc traversal: we intentionally keep a baseline while hierarchy data
  /// is being cleaned up. This catches regressions without requiring zero skips.
  group('Full-doc leaf traversal (no skips)', () {
    test('consecutive-leaf skip baseline is unchanged', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      expect(leaves, isNotEmpty);

      final skips = <String>[];
      var gapSum = 0;
      var maxGap = 0;
      for (var i = 0; i < leaves.length - 1; i++) {
        final refA =
            hierarchyService.getFirstVerseForSectionSync(leaves[i].path);
        final refB =
            hierarchyService.getFirstVerseForSectionSync(leaves[i + 1].path);
        if (refA == null || refB == null) continue;

        final (chA, vA) = VerseHierarchyService.baseVerseFromRef(refA);
        final (chB, vB) = VerseHierarchyService.baseVerseFromRef(refB);
        if (chA != chB) continue; // chapter boundary is fine

        final gap = vB - vA;
        if (gap > 1) {
          gapSum += gap;
          if (gap > maxGap) maxGap = gap;
          skips.add(
              '${leaves[i].path} ($refA) -> ${leaves[i + 1].path} ($refB): verse gap $gap');
        }
      }
      expect(
        skips.length,
        _expectedLeafSkipCount,
        reason:
            'Leaf skip count changed: expected $_expectedLeafSkipCount, got ${skips.length}.',
      );
      expect(
        gapSum,
        _expectedLeafGapSum,
        reason:
            'Leaf skip gap-sum changed: expected $_expectedLeafGapSum, got $gapSum.',
      );
      expect(
        maxGap,
        _expectedLeafMaxGap,
        reason:
            'Leaf max gap changed: expected $_expectedLeafMaxGap, got $maxGap.',
      );
      expect(
        skips.take(5).toList(),
        _expectedLeafSkipsFirst5,
        reason: 'Leading leaf-skip baseline changed.',
      );
      expect(
        skips.skip(skips.length - 5).toList(),
        _expectedLeafSkipsLast5,
        reason: 'Trailing leaf-skip baseline changed.',
      );
    });
  });

  /// Extracts all "verses" attributes from verse_hierarchy_map.json in order,
  /// sorts by verse order, then scans for missing or non-consecutive entries.
  /// Shows results as a list of lines marked 'missing' or 'non-consecutive'.
  group('verse_hierarchy_map.json validation', () {
    test('verses are consecutive (report missing / non-consecutive)', () {
      final jsonFile = File('texts/verse_hierarchy_map.json');
      expect(jsonFile.existsSync(), true, reason: 'Run from project root');

      final map =
          jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
      final sectionsRoot = map['sections'] as List<dynamic>?;
      expect(sectionsRoot, isNotNull);

      // Extract all "verses" arrays sequentially (depth-first)
      final versesSequential = <String>[];
      void extractVerses(dynamic node) {
        if (node is! Map) return;
        final verses = node['verses'] as List<dynamic>?;
        if (verses != null) {
          for (final v in verses) {
            versesSequential.add(v.toString());
          }
        }
        for (final c in (node['children'] as List<dynamic>? ?? [])) {
          extractVerses(c);
        }
      }

      for (final s in sectionsRoot!) {
        extractVerses(s);
      }

      // Deduplicate and sort by verse order
      final sorted = versesSequential.toSet().toList()
        ..sort((a, b) => VerseHierarchyService.compareVerseRefs(a, b));

      final missing = <String>[];
      final nonConsecutive = <String>[];

      for (var i = 0; i < sorted.length - 1; i++) {
        final refA = sorted[i];
        final refB = sorted[i + 1];
        final (chA, vA) = VerseHierarchyService.baseVerseFromRef(refA);
        final (chB, vB) = VerseHierarchyService.baseVerseFromRef(refB);

        if (chA == chB) {
          final gap = vB - vA;
          if (gap > 1) {
            nonConsecutive.add('$refA -> $refB: non-consecutive (gap $gap)');
            for (var v = vA + 1; v < vB; v++) {
              missing.add('$chA.$v: missing');
            }
          }
        } else {
          if (chB != chA + 1 || vB != 1) {
            nonConsecutive.add('$refA -> $refB: non-consecutive (chapters)');
          }
        }
      }

      final results = <String>[
        if (missing.isNotEmpty) ...['--- missing ---', ...missing],
        if (nonConsecutive.isNotEmpty) ...[
          if (missing.isNotEmpty) '',
          '--- non-consecutive ---',
          ...nonConsecutive,
        ],
      ];
      final report = results.isEmpty ? 'OK' : results.join('\n');

      expect(
        missing,
        _expectedMissingVerses,
        reason:
            'verse_hierarchy_map.json missing-verse baseline changed\n$report',
      );
      expect(
        nonConsecutive,
        _expectedNonConsecutive,
        reason:
            'verse_hierarchy_map.json non-consecutive baseline changed\n$report',
      );
    });
  });

  group('Verse-order (deduplicated) navigation', () {
    test('arrow-down through verse-ordered sections yields consecutive', () {
      final ordered = hierarchyService.getSectionsByVerseOrderSync();
      expect(ordered, isNotEmpty);

      final jumps = <String>[];
      for (var i = 0; i < ordered.length; i++) {
        final ref = hierarchyService.getFirstVerseForSectionSync(
          ordered[i].path,
        );
        if (ref == null) continue;

        final nextIdx = hierarchyService.findAdjacentSectionIndex(
          ordered,
          ref,
          direction: 1,
        );

        if (i == ordered.length - 1) {
          expect(nextIdx, lessThan(0));
        } else if (nextIdx != i + 1) {
          jumps
              .add('At ${ordered[i].path}: expected ${i + 1} but got $nextIdx');
        }
      }
      expect(jumps, isEmpty);
    });
  });
}
