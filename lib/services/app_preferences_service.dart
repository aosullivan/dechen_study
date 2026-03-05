import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/study_destination_catalog.dart';

class AppPreferences {
  const AppPreferences({
    required this.selectedTextIds,
    required this.onboardingCompleted,
    required this.dailyNotificationsEnabled,
    required this.dailyNotificationMinutesLocal,
  });

  final Set<String> selectedTextIds;
  final bool onboardingCompleted;
  final bool dailyNotificationsEnabled;
  final int dailyNotificationMinutesLocal;

  AppPreferences copyWith({
    Set<String>? selectedTextIds,
    bool? onboardingCompleted,
    bool? dailyNotificationsEnabled,
    int? dailyNotificationMinutesLocal,
  }) {
    return AppPreferences(
      selectedTextIds: selectedTextIds ?? this.selectedTextIds,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      dailyNotificationsEnabled:
          dailyNotificationsEnabled ?? this.dailyNotificationsEnabled,
      dailyNotificationMinutesLocal:
          dailyNotificationMinutesLocal ?? this.dailyNotificationMinutesLocal,
    );
  }
}

class AppPreferencesService {
  AppPreferencesService._();

  static final AppPreferencesService instance = AppPreferencesService._();

  static const String _selectedTextIdsKey = 'selected_text_ids';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _dailyNotificationsEnabledKey =
      'daily_notifications_enabled';
  static const String _dailyNotificationMinutesLocalKey =
      'daily_notification_minutes_local';

  static const int defaultDailyNotificationMinutesLocal = 8 * 60;
  static bool get defaultDailyNotificationsEnabled {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<AppPreferences> load() async {
    final prefs = await _sp;

    final onboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
    final dailyNotificationsEnabled =
        prefs.getBool(_dailyNotificationsEnabledKey) ??
            defaultDailyNotificationsEnabled;

    final persistedMinutes = prefs.getInt(_dailyNotificationMinutesLocalKey) ??
        defaultDailyNotificationMinutesLocal;
    final dailyNotificationMinutesLocal = _normalizeMinutes(persistedMinutes);

    final validIds = allStudyDestinationIds();
    final rawSelected =
        (prefs.getStringList(_selectedTextIdsKey) ?? const <String>[])
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty && validIds.contains(id))
            .toSet();

    final selectedTextIds = (onboardingCompleted && rawSelected.isEmpty)
        ? <String>{gatewayDestinationId}
        : rawSelected;

    return AppPreferences(
      selectedTextIds: selectedTextIds,
      onboardingCompleted: onboardingCompleted,
      dailyNotificationsEnabled: dailyNotificationsEnabled,
      dailyNotificationMinutesLocal: dailyNotificationMinutesLocal,
    );
  }

  Future<void> save(AppPreferences preferences) async {
    _validateSelection(preferences.selectedTextIds);
    final prefs = await _sp;
    await prefs.setStringList(
      _selectedTextIdsKey,
      preferences.selectedTextIds.toList()..sort(),
    );
    await prefs.setBool(
      _onboardingCompletedKey,
      preferences.onboardingCompleted,
    );
    await prefs.setBool(
      _dailyNotificationsEnabledKey,
      preferences.dailyNotificationsEnabled,
    );
    await prefs.setInt(
      _dailyNotificationMinutesLocalKey,
      _normalizeMinutes(preferences.dailyNotificationMinutesLocal),
    );
  }

  Future<void> completeOnboarding(Set<String> selectedTextIds) async {
    _validateSelection(selectedTextIds);
    final current = await load();
    await save(current.copyWith(
      selectedTextIds: selectedTextIds,
      onboardingCompleted: true,
    ));
  }

  Future<void> updateSelectedTextIds(Set<String> selectedTextIds) async {
    _validateSelection(selectedTextIds);
    final current = await load();
    await save(current.copyWith(selectedTextIds: selectedTextIds));
  }

  Future<void> setDailyNotificationsEnabled(bool enabled) async {
    final current = await load();
    await save(current.copyWith(dailyNotificationsEnabled: enabled));
  }

  Future<void> setDailyNotificationMinutesLocal(int minutesLocal) async {
    final current = await load();
    await save(current.copyWith(
      dailyNotificationMinutesLocal: _normalizeMinutes(minutesLocal),
    ));
  }

  Future<void> resetForTest() async {
    final prefs = await _sp;
    await prefs.remove(_selectedTextIdsKey);
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_dailyNotificationsEnabledKey);
    await prefs.remove(_dailyNotificationMinutesLocalKey);
  }

  int _normalizeMinutes(int value) {
    if (value < 0 || value >= 24 * 60) {
      return defaultDailyNotificationMinutesLocal;
    }
    return value;
  }

  void _validateSelection(Set<String> selectedTextIds) {
    if (selectedTextIds.isEmpty) {
      throw ArgumentError('selectedTextIds must contain at least one item');
    }

    final validIds = allStudyDestinationIds();
    for (final id in selectedTextIds) {
      if (!validIds.contains(id)) {
        throw ArgumentError('Unknown destination id: $id');
      }
    }
  }
}
