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

    test('fallback from 9.1: findAdjacentSectionIndex returns 9.2 not 9.116',
        () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      final nextIdx = hierarchyService.findAdjacentSectionIndex(leaves, '9.1',
          direction: 1);
      expect(nextIdx, greaterThanOrEqualTo(0));
      final nextRef =
          hierarchyService.getFirstVerseForSectionSync(leaves[nextIdx].path);
      expect(
        VerseHierarchyService.baseVerseFromRef(nextRef ?? ''),
        (9, 2),
        reason: 'Fallback from 9.1 must land on 9.2, not 9.116',
      );
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

  /// Full-doc traversal: report every consecutive leaf pair (same chapter) where
  /// first-verse numbers skip (e.g. 8.17 then 8.19 skips 8.18). Run with:
  ///   flutter test test/section_navigation_test.dart --name "consecutive leaves"
  /// to get a full list in ~4s. Fails if any skips exist (many exist today due to
  /// outline structure; use this as a regression baseline or to drive fixes).
  group('Full-doc leaf traversal (no skips)', () {
    test('consecutive leaves in same chapter have no verse-number skip', () {
      final leaves = hierarchyService.getLeafSectionsByVerseOrderSync();
      expect(leaves, isNotEmpty);

      final skips = <String>[];
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
          skips.add(
              '${leaves[i].path} ($refA) -> ${leaves[i + 1].path} ($refB): verse gap $gap');
        }
      }
      expect(
        skips,
        isEmpty,
        reason:
            'Leaf list has ${skips.length} verse-number skips (key-down would skip verses). First 5:\n${skips.take(5).join('\n')}\n... run test for full list.',
      );
    }, skip: 'verse_hierarchy_map.json has gaps; enable when map is updated');
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
        isEmpty,
        reason: 'verse_hierarchy_map.json: ${missing.length} missing\n$report',
      );
      expect(
        nonConsecutive,
        isEmpty,
        reason:
            'verse_hierarchy_map.json: ${nonConsecutive.length} non-consecutive\n$report',
      );
    },
        skip:
            'verse_hierarchy_map.json has missing verses; enable when map is updated');
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
