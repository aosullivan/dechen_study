import 'package:flutter/foundation.dart';

/// Coarse navigation lifecycle for the reader pane.
enum ReaderNavMode {
  idle,
  programmatic,
  cooldown,
}

/// Immutable state for reader navigation orchestration.
@immutable
class ReaderNavState {
  const ReaderNavState({
    required this.syncGeneration,
    required this.mode,
    this.cooldownUntil,
    this.lastArrowNavAt,
  });

  const ReaderNavState.initial()
      : syncGeneration = 0,
        mode = ReaderNavMode.idle,
        cooldownUntil = null,
        lastArrowNavAt = null;

  final int syncGeneration;
  final ReaderNavMode mode;
  final DateTime? cooldownUntil;
  final DateTime? lastArrowNavAt;

  bool isCooldownActive(DateTime now) {
    return mode == ReaderNavMode.cooldown &&
        cooldownUntil != null &&
        now.isBefore(cooldownUntil!);
  }

  bool get isProgrammatic => mode == ReaderNavMode.programmatic;

  ReaderNavState copyWith({
    int? syncGeneration,
    ReaderNavMode? mode,
    DateTime? cooldownUntil,
    DateTime? lastArrowNavAt,
    bool clearCooldownUntil = false,
    bool clearLastArrowNavAt = false,
  }) {
    return ReaderNavState(
      syncGeneration: syncGeneration ?? this.syncGeneration,
      mode: mode ?? this.mode,
      cooldownUntil:
          clearCooldownUntil ? null : (cooldownUntil ?? this.cooldownUntil),
      lastArrowNavAt:
          clearLastArrowNavAt ? null : (lastArrowNavAt ?? this.lastArrowNavAt),
    );
  }
}

@immutable
sealed class ReaderNavEvent {
  const ReaderNavEvent();
}

/// Keep state transitions deterministic when time advances.
final class ReaderNavTick extends ReaderNavEvent {
  const ReaderNavTick();
}

/// Start a programmatic navigation pass (chapter/section/arrow jump).
final class ReaderProgrammaticStart extends ReaderNavEvent {
  const ReaderProgrammaticStart({this.bumpGeneration = true});
  final bool bumpGeneration;
}

/// Mark programmatic navigation as settled and enter cooldown.
final class ReaderProgrammaticSettled extends ReaderNavEvent {
  const ReaderProgrammaticSettled(this.cooldown);
  final Duration cooldown;
}

/// Attempt an arrow navigation step with debounce.
final class ReaderArrowAttempt extends ReaderNavEvent {
  const ReaderArrowAttempt(this.debounce);
  final Duration debounce;
}

@immutable
class ReaderNavTransition {
  const ReaderNavTransition({
    required this.state,
    this.arrowAccepted = false,
  });

  final ReaderNavState state;
  final bool arrowAccepted;
}

/// Pure reducer for reader-navigation transitions.
abstract final class ReaderNavReducer {
  static ReaderNavTransition reduce(
    ReaderNavState state,
    ReaderNavEvent event, {
    required DateTime now,
  }) {
    final normalized = _normalize(state, now);

    if (event is ReaderNavTick) {
      return ReaderNavTransition(state: normalized);
    }

    if (event is ReaderProgrammaticStart) {
      return ReaderNavTransition(
        state: normalized.copyWith(
          syncGeneration: event.bumpGeneration
              ? normalized.syncGeneration + 1
              : normalized.syncGeneration,
          mode: ReaderNavMode.programmatic,
          clearCooldownUntil: true,
        ),
      );
    }

    if (event is ReaderProgrammaticSettled) {
      return ReaderNavTransition(
        state: normalized.copyWith(
          mode: ReaderNavMode.cooldown,
          cooldownUntil: now.add(event.cooldown),
        ),
      );
    }

    if (event is ReaderArrowAttempt) {
      final last = normalized.lastArrowNavAt;
      final accepted = last == null || now.difference(last) >= event.debounce;
      return ReaderNavTransition(
        state: accepted ? normalized.copyWith(lastArrowNavAt: now) : normalized,
        arrowAccepted: accepted,
      );
    }

    return ReaderNavTransition(state: normalized);
  }

  static ReaderNavState _normalize(ReaderNavState state, DateTime now) {
    if (state.mode != ReaderNavMode.cooldown) return state;
    if (state.cooldownUntil == null || !now.isBefore(state.cooldownUntil!)) {
      return state.copyWith(mode: ReaderNavMode.idle, clearCooldownUntil: true);
    }
    return state;
  }
}
