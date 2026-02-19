library;

import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/screens/landing/bcv/reader_nav_state.dart';

void main() {
  group('ReaderNavReducer', () {
    test('programmatic start bumps generation and enters programmatic mode',
        () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final initial = const ReaderNavState.initial();

      final t1 = ReaderNavReducer.reduce(
        initial,
        const ReaderProgrammaticStart(),
        now: now,
      );

      expect(t1.state.syncGeneration, 1);
      expect(t1.state.mode, ReaderNavMode.programmatic);
      expect(t1.state.isProgrammatic, isTrue);
    });

    test('arrow attempt is debounced by configured duration', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final initial = const ReaderNavState.initial();

      final first = ReaderNavReducer.reduce(
        initial,
        const ReaderArrowAttempt(Duration(milliseconds: 200)),
        now: now,
      );
      expect(first.arrowAccepted, isTrue);

      final second = ReaderNavReducer.reduce(
        first.state,
        const ReaderArrowAttempt(Duration(milliseconds: 200)),
        now: now.add(const Duration(milliseconds: 50)),
      );
      expect(second.arrowAccepted, isFalse);

      final third = ReaderNavReducer.reduce(
        second.state,
        const ReaderArrowAttempt(Duration(milliseconds: 200)),
        now: now.add(const Duration(milliseconds: 250)),
      );
      expect(third.arrowAccepted, isTrue);
    });

    test('programmatic settled enters cooldown then normalizes to idle', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final started = ReaderNavReducer.reduce(
        const ReaderNavState.initial(),
        const ReaderProgrammaticStart(),
        now: now,
      );

      final settled = ReaderNavReducer.reduce(
        started.state,
        const ReaderProgrammaticSettled(Duration(milliseconds: 600)),
        now: now,
      );

      expect(settled.state.mode, ReaderNavMode.cooldown);
      expect(settled.state.isCooldownActive(now), isTrue);
      expect(
        settled.state
            .isCooldownActive(now.add(const Duration(milliseconds: 700))),
        isFalse,
      );

      final normalized = ReaderNavReducer.reduce(
        settled.state,
        const ReaderNavTick(),
        now: now.add(const Duration(milliseconds: 700)),
      );
      expect(normalized.state.mode, ReaderNavMode.idle);
      expect(normalized.state.cooldownUntil, isNull);
    });

    test('programmatic start clears active cooldown and bumps generation', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final cooled = ReaderNavReducer.reduce(
        const ReaderNavState.initial(),
        const ReaderProgrammaticSettled(Duration(milliseconds: 600)),
        now: now,
      );
      expect(cooled.state.mode, ReaderNavMode.cooldown);
      expect(cooled.state.isCooldownActive(now), isTrue);

      final restarted = ReaderNavReducer.reduce(
        cooled.state,
        const ReaderProgrammaticStart(),
        now: now.add(const Duration(milliseconds: 200)),
      );
      expect(restarted.state.mode, ReaderNavMode.programmatic);
      expect(restarted.state.cooldownUntil, isNull);
      expect(restarted.state.syncGeneration, 1);
    });
  });
}
