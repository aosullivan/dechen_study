import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/usage_metrics_service.dart';

/// Shared lifecycle + dwell tracking for top-level study surfaces.
mixin SurfaceDwellTracker<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  final UsageMetricsService _usageMetrics = UsageMetricsService.instance;
  DateTime? _surfaceDwellStartedAt;

  @protected
  String get dwellTextId;

  @protected
  String get dwellMode;

  @protected
  String? get dwellSectionPath => null;

  @protected
  String? get dwellSectionTitle => null;

  @protected
  int? get dwellChapterNumber => null;

  @protected
  String? get dwellVerseRef => null;

  @protected
  Map<String, dynamic>? get dwellProperties => null;

  @protected
  void startSurfaceDwellTracking() {
    _surfaceDwellStartedAt = DateTime.now().toUtc();
  }

  @protected
  void flushSurfaceDwell({required bool resetStart}) {
    final startedAt = _surfaceDwellStartedAt;
    if (startedAt == null) return;
    final nowUtc = DateTime.now().toUtc();
    final durationMs = nowUtc.difference(startedAt).inMilliseconds;
    if (durationMs >= _usageMetrics.minDwellMs) {
      unawaited(_usageMetrics.trackSurfaceDwell(
        textId: dwellTextId,
        mode: dwellMode,
        durationMs: durationMs,
        sectionPath: dwellSectionPath,
        sectionTitle: dwellSectionTitle,
        chapterNumber: dwellChapterNumber,
        verseRef: dwellVerseRef,
        properties: dwellProperties,
      ));
    }
    if (resetStart) _surfaceDwellStartedAt = null;
  }

  @protected
  void flushSurfaceDwellQueue() {
    unawaited(_usageMetrics.flush(all: true));
  }

  @protected
  void handleSurfaceLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      flushSurfaceDwell(resetStart: true);
      flushSurfaceDwellQueue();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _surfaceDwellStartedAt ??= DateTime.now().toUtc();
    }
  }
}
