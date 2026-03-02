import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Centralized usage analytics sink for app product metrics.
///
/// Stores a lightweight in-memory queue and batches writes to Supabase.
class UsageMetricsService {
  UsageMetricsService._();

  static final UsageMetricsService instance = UsageMetricsService._();

  static const _anonIdKey = 'usage_metrics_anon_id';
  static const _flushBatchSize = 20;
  static const _flushDelay = Duration(seconds: 8);
  static const _defaultMinDwellMs = 1000;
  static const _randomUpperBound = 0xFFFFFFFF;

  final List<Map<String, dynamic>> _pending = <Map<String, dynamic>>[];
  final String _sessionId = _createSessionId();
  Timer? _flushTimer;

  bool _initialized = false;
  bool _isFlushing = false;
  String? _anonId;
  String? _countryCode;
  Future<void>? _countryCodeFuture;
  int _minDwellMs = _defaultMinDwellMs;
  bool _disabledForSession = false;
  String? _disabledReason;

  bool? _enabledOverrideForTest;
  Future<void> Function(List<Map<String, dynamic>> batch)?
      _insertBatchOverrideForTest;
  String? Function()? _currentUserIdOverrideForTest;
  DateTime Function()? _nowOverrideForTest;
  bool _disableAutoFlushOverrideForTest = false;

  int get minDwellMs => _minDwellMs;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (!_isEnabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_anonIdKey)?.trim();
      if (existing != null && existing.isNotEmpty) {
        _anonId = existing;
        return;
      }
      final created = _createAnonId();
      await prefs.setString(_anonIdKey, created);
      _anonId = created;
    } catch (e) {
      debugPrint('usage_metrics init error: $e');
      // Keep analytics best-effort; fallback ID remains process-local.
      _anonId ??= _createAnonId();
    }
    unawaited(_fetchCountryCode());
  }

  static const _geoUrl = 'https://ipapi.co/json/';

  Future<void> _fetchCountryCode() async {
    if (_countryCodeFuture != null) return;
    _countryCodeFuture = _fetchCountryCodeImpl();
    await _countryCodeFuture;
  }

  Future<void> _fetchCountryCodeImpl() async {
    try {
      final response = await http.get(Uri.parse(_geoUrl)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('', 408),
      );
      if (response.statusCode != 200) return;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      final code = map?['country_code'] as String?;
      if (code != null && code.trim().isNotEmpty) {
        _countryCode = code.trim().toUpperCase();
        for (final event in _pending) {
          if (event['country_code'] == null) event['country_code'] = _countryCode;
        }
      }
    } catch (_) {
      // Best-effort; leave _countryCode null.
    }
  }

  Future<void> trackTextOptionTapped({
    required String textId,
    required String targetMode,
  }) {
    return trackEvent(
      eventName: 'text_option_tapped',
      textId: textId,
      mode: targetMode,
    );
  }

  Future<void> trackSurfaceDwell({
    required String textId,
    required String mode,
    required int durationMs,
    int? chapterNumber,
    String? sectionPath,
    String? sectionTitle,
    String? verseRef,
    Map<String, dynamic>? properties,
  }) {
    return trackEvent(
      eventName: 'surface_dwell',
      textId: textId,
      mode: mode,
      durationMs: durationMs,
      chapterNumber: chapterNumber,
      sectionPath: sectionPath,
      sectionTitle: sectionTitle,
      verseRef: verseRef,
      properties: properties,
      flushNow: true,
    );
  }

  Future<void> trackReadSectionDwell({
    required String textId,
    required String sectionPath,
    required int durationMs,
    String? sectionTitle,
    int? chapterNumber,
    String? verseRef,
    Map<String, dynamic>? properties,
  }) {
    return trackEvent(
      eventName: 'read_section_dwell',
      textId: textId,
      mode: 'read',
      sectionPath: sectionPath,
      sectionTitle: sectionTitle,
      chapterNumber: chapterNumber,
      verseRef: verseRef,
      durationMs: durationMs,
      properties: properties,
      flushNow: true,
    );
  }

  Future<void> trackQuizAttempt({
    required String textId,
    required String mode,
    required bool correct,
    int? chapterNumber,
    String? difficulty,
    String? verseRef,
  }) {
    return trackEvent(
      eventName: 'quiz_attempt',
      textId: textId,
      mode: mode,
      chapterNumber: chapterNumber,
      verseRef: verseRef,
      properties: {
        'correct': correct,
        if (difficulty != null && difficulty.isNotEmpty)
          'difficulty': difficulty,
      },
    );
  }

  Future<void> trackEvent({
    required String eventName,
    DateTime? occurredAt,
    String? textId,
    String? mode,
    String? sectionPath,
    String? sectionTitle,
    int? chapterNumber,
    String? verseRef,
    int? durationMs,
    Map<String, dynamic>? properties,
    bool flushNow = false,
  }) async {
    if (!_isEnabled) return;
    await init();
    final normalizedName = eventName.trim();
    if (normalizedName.isEmpty) return;

    final actorUserId = _currentUserId;
    final actorAnonId =
        actorUserId == null ? (_anonId ?? _createAnonId()) : null;
    final ts = (occurredAt ?? _nowUtc).toUtc().toIso8601String();
    final normalizedProps = properties == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(properties);
    normalizedProps.putIfAbsent('environment', () => appEnvironment);

    _pending.add({
      'event_name': normalizedName,
      'occurred_at': ts,
      'session_id': _sessionId,
      'user_id': actorUserId,
      'anon_id': actorAnonId,
      'country_code': _countryCode,
      'text_id': _normalizeText(textId),
      'mode': _normalizeText(mode),
      'section_path': _normalizeText(sectionPath),
      'section_title': _normalizeText(sectionTitle),
      'chapter_number': chapterNumber,
      'verse_ref': _normalizeText(verseRef),
      'duration_ms': durationMs,
      'properties': normalizedProps,
    });

    if (flushNow ||
        (_pending.length >= _flushBatchSize &&
            !_disableAutoFlushOverrideForTest)) {
      unawaited(flush(all: flushNow));
      return;
    }
    _scheduleFlush();
  }

  Future<void> flush({bool all = false}) async {
    if (!_isEnabled || _pending.isEmpty || _isFlushing) return;

    _flushTimer?.cancel();
    _flushTimer = null;
    _isFlushing = true;
    try {
      do {
        final batchSize =
            all ? _pending.length : min(_flushBatchSize, _pending.length);
        final batch = List<Map<String, dynamic>>.from(_pending.take(batchSize));
        await _insertBatch(batch);
        _pending.removeRange(0, batch.length);
      } while (all && _pending.isNotEmpty);
    } catch (e) {
      if (_isMissingUsageTableError(e)) {
        _disabledForSession = true;
        _disabledReason = 'app_usage_events table not found (PGRST205)';
        _pending.clear();
        _flushTimer?.cancel();
        _flushTimer = null;
        debugPrint('usage_metrics disabled for session: $_disabledReason');
        return;
      }
      debugPrint('usage_metrics flush error: $e');
    } finally {
      _isFlushing = false;
      if (_pending.isNotEmpty) _scheduleFlush();
    }
  }

  bool _isMissingUsageTableError(Object error) {
    final message = error.toString();
    return message.contains('PGRST205') &&
        message.contains("public.app_usage_events");
  }

  void _scheduleFlush() {
    if (_flushTimer != null || _pending.isEmpty) return;
    _flushTimer = Timer(_flushDelay, () {
      _flushTimer = null;
      unawaited(flush());
    });
  }

  Future<void> onAppLifecycleStateChanged(AppLifecycleState state) async {
    if (!_isEnabled) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      await flush(all: true);
    }
  }

  bool get _isEnabled {
    if (_disabledForSession) return false;
    final override = _enabledOverrideForTest;
    if (override != null) return override;
    return isSupabaseConfigured && _isSupabaseReady;
  }

  bool get _isSupabaseReady {
    try {
      // Touch the client once to validate initialization.
      // If Supabase failed to initialize, this throws and we disable metrics.
      supabase.auth.currentUser;
      return true;
    } catch (e) {
      debugPrint('usage_metrics supabase unavailable: $e');
      return false;
    }
  }

  String? get _currentUserId {
    final override = _currentUserIdOverrideForTest;
    if (override != null) return override();
    return supabase.auth.currentUser?.id;
  }

  DateTime get _nowUtc =>
      (_nowOverrideForTest?.call() ?? DateTime.now()).toUtc();

  Future<void> _insertBatch(List<Map<String, dynamic>> batch) async {
    final override = _insertBatchOverrideForTest;
    if (override != null) {
      await override(batch);
      return;
    }
    await supabase.from('app_usage_events').insert(batch);
  }

  @visibleForTesting
  int get pendingCount => _pending.length;

  @visibleForTesting
  void configureForTesting({
    bool enabled = true,
    int? minDwellMs,
    String? anonId,
    Future<void> Function(List<Map<String, dynamic>> batch)? insertBatch,
    String? Function()? currentUserId,
    DateTime Function()? nowUtc,
    bool initialized = true,
    bool disableAutoFlush = false,
  }) {
    _enabledOverrideForTest = enabled;
    _insertBatchOverrideForTest = insertBatch;
    _currentUserIdOverrideForTest = currentUserId;
    _nowOverrideForTest = nowUtc;
    _initialized = initialized;
    _disableAutoFlushOverrideForTest = disableAutoFlush;
    if (anonId != null) _anonId = anonId;
    if (minDwellMs != null) _minDwellMs = minDwellMs;
  }

  @visibleForTesting
  void resetForTesting() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending.clear();
    _isFlushing = false;
    _initialized = false;
    _anonId = null;
    _countryCode = null;
    _countryCodeFuture = null;
    _minDwellMs = _defaultMinDwellMs;
    _disabledForSession = false;
    _disabledReason = null;
    _enabledOverrideForTest = null;
    _insertBatchOverrideForTest = null;
    _currentUserIdOverrideForTest = null;
    _nowOverrideForTest = null;
    _disableAutoFlushOverrideForTest = false;
  }

  static String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _createSessionId() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final rand = Random.secure().nextInt(_randomUpperBound);
    return 's_${now.toRadixString(36)}_${rand.toRadixString(36)}';
  }

  static String _createAnonId() {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    final rand = Random.secure().nextInt(_randomUpperBound);
    return 'a_${now.toRadixString(36)}_${rand.toRadixString(36)}';
  }
}
