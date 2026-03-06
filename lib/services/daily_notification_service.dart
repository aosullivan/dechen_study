import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../config/study_destination_catalog.dart';
import '../config/study_text_config.dart';
import 'app_preferences_service.dart';
import 'daily_verse_picker_service.dart';
import 'verse_service.dart';

enum DailyNotificationIntentType { dailyVerse }

class DailyNotificationIntent {
  const DailyNotificationIntent({
    required this.type,
    required this.createdAt,
  });

  final DailyNotificationIntentType type;
  final DateTime createdAt;
}

class DailyNotificationService {
  DailyNotificationService._();

  static final DailyNotificationService instance = DailyNotificationService._();

  static const int _dailyNotificationBaseId = 41000;
  static const int _dailyNotificationSlotCount = 30;
  static const String _androidChannelId = 'daily_verses_channel';
  static const int _maxPreviewBodyLength = 120;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<DailyNotificationIntent> _intentController =
      StreamController<DailyNotificationIntent>.broadcast();

  DailyNotificationIntent? _pendingLaunchIntent;
  bool _initialized = false;
  bool _timeZoneInitialized = false;

  Stream<DailyNotificationIntent> get intentStream => _intentController.stream;

  DailyNotificationIntent? get pendingLaunchIntent => _pendingLaunchIntent;

  DailyNotificationIntent? takePendingLaunchIntent() {
    final pending = _pendingLaunchIntent;
    _pendingLaunchIntent = null;
    return pending;
  }

  Future<void> init() async {
    if (_initialized || !_isSupportedPlatform) return;
    _initialized = true;

    await _ensureTimeZoneInitialized();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final intent = _intentFromPayload(
        launchDetails?.notificationResponse?.payload,
      );
      if (intent != null) {
        _pendingLaunchIntent = intent;
      }
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    if (!_isSupportedPlatform) return false;
    await init();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> applySchedule(AppPreferences preferences) async {
    if (!_isSupportedPlatform) return;
    await init();

    if (!preferences.dailyNotificationsEnabled) {
      await cancel();
      return;
    }

    if (getDailyEligibleDestinations(preferences.selectedTextIds).isEmpty) {
      await cancel();
      return;
    }

    await _cancelScheduledDailyNotifications();

    final hour = preferences.dailyNotificationMinutesLocal ~/ 60;
    final minute = preferences.dailyNotificationMinutesLocal % 60;

    final now = tz.TZDateTime.now(tz.local);
    var firstScheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!firstScheduled.isAfter(now)) {
      firstScheduled = firstScheduled.add(const Duration(days: 1));
    }

    final firstLocalDate = DateTime(
      firstScheduled.year,
      firstScheduled.month,
      firstScheduled.day,
    );

    const fallbackTitle = 'Daily verses';
    const fallbackBody = 'Open Dechen Study to read today\'s verses.';
    for (var i = 0; i < _dailyNotificationSlotCount; i++) {
      final localDate = firstLocalDate.add(Duration(days: i));
      final scheduled = tz.TZDateTime(
        tz.local,
        localDate.year,
        localDate.month,
        localDate.day,
        hour,
        minute,
      );

      if (!scheduled.isAfter(now)) {
        continue;
      }

      final preview = await _buildPreviewForDate(localDate, preferences);
      final title = preview?.title ?? fallbackTitle;
      final body = preview?.body ?? fallbackBody;
      final payload = jsonEncode({
        'type': 'daily',
        'date': '${localDate.year.toString().padLeft(4, '0')}-'
            '${localDate.month.toString().padLeft(2, '0')}-'
            '${localDate.day.toString().padLeft(2, '0')}',
      });

      await _plugin.zonedSchedule(
        _dailyNotificationBaseId + i,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            'Daily verses',
            channelDescription: 'Daily reminder to review verses.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancel() async {
    if (!_isSupportedPlatform) return;
    await _cancelScheduledDailyNotifications();
  }

  Future<({String title, String body})?> _buildPreviewForDate(
    DateTime localDate,
    AppPreferences preferences,
  ) async {
    try {
      final eligible =
          getDailyEligibleDestinations(preferences.selectedTextIds);
      if (eligible.isEmpty) return null;

      final textId = DailyVersePickerService.instance.pickDailyTextId(
        localDate,
        preferences.selectedTextIds,
      );
      if (textId == null) return null;

      final section = await DailyVersePickerService.instance.pickDailySection(
        textId,
        localDate,
      );
      if (section == null || section.refsInBlock.isEmpty) return null;

      await VerseService.instance.getChapters(textId);

      String? previewText;
      for (final ref in section.refsInBlock) {
        final index =
            VerseService.instance.getIndexForRefWithFallback(textId, ref);
        if (index == null) continue;
        final fullText = VerseService.instance.getVerseAt(textId, index);
        if (fullText == null) continue;
        final lines = fullText.split('\n');
        final range = VerseService.lineRangeForSegmentRef(ref, lines.length);
        if (range != null && range.length >= 2) {
          final start = range[0].clamp(0, lines.length - 1);
          final end = (range[1] + 1).clamp(start, lines.length);
          previewText = lines.sublist(start, end).join('\n').trim();
        } else {
          previewText = fullText.trim();
        }
        if (previewText.isNotEmpty) break;
      }
      if (previewText == null || previewText.isEmpty) return null;

      var body = previewText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (body.length > _maxPreviewBodyLength) {
        body = '${body.substring(0, _maxPreviewBodyLength)}…';
      }
      final title = getStudyText(textId)?.title ?? 'Daily verses';
      return (title: title, body: body);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureTimeZoneInitialized() async {
    if (_timeZoneInitialized) return;
    _timeZoneInitialized = true;

    tzdata.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final intent = _intentFromPayload(response.payload);
    if (intent == null) return;
    _intentController.add(intent);
  }

  DailyNotificationIntent? _intentFromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      final type = decoded['type']?.toString();
      if (type != 'daily') return null;
      return DailyNotificationIntent(
        type: DailyNotificationIntentType.dailyVerse,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _cancelScheduledDailyNotifications() async {
    for (var i = 0; i < _dailyNotificationSlotCount; i++) {
      await _plugin.cancel(_dailyNotificationBaseId + i);
    }
  }
}

@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse response) {
  // Background tap handling is routed through app launch details/response stream
  // in this app's startup flow.
}
