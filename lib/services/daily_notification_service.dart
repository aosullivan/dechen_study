import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../config/study_destination_catalog.dart';
import 'app_preferences_service.dart';

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

  static const int _dailyNotificationId = 41001;
  static const String _androidChannelId = 'daily_verses_channel';

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

    final hour = preferences.dailyNotificationMinutesLocal ~/ 60;
    final minute = preferences.dailyNotificationMinutesLocal % 60;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      'Daily verses',
      'Open Dechen Study to read today\'s verses.',
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
      payload: jsonEncode({'type': 'daily'}),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    if (!_isSupportedPlatform) return;
    await _plugin.cancel(_dailyNotificationId);
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
}

@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse response) {
  // Background tap handling is routed through app launch details/response stream
  // in this app's startup flow.
}
