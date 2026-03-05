import 'package:flutter/material.dart';

import '../config/study_text_config.dart';
import '../screens/landing/daily_verse_screen.dart';
import '../screens/mobile/mobile_home_screen.dart';
import '../utils/app_navigation.dart';
import 'app_preferences_service.dart';
import 'daily_verse_picker_service.dart';

class DailyNotificationNavigation {
  DailyNotificationNavigation._();

  static Future<void> openTodayFromNotification({
    required bool replaceStack,
  }) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final preferences = await AppPreferencesService.instance.load();
    final now = DateTime.now();
    final textId = DailyVersePickerService.instance
        .pickDailyTextId(now, preferences.selectedTextIds);

    if (textId == null) {
      final route = MaterialPageRoute<void>(
        builder: (_) => const MobileHomeScreen(showDailySettingsPrompt: true),
      );
      if (replaceStack) {
        navigator.pushAndRemoveUntil(route, (r) => false);
      } else {
        navigator.push(route);
      }
      return;
    }

    final title = getStudyText(textId)?.title ?? 'Daily verses';
    final route = MaterialPageRoute<void>(
      builder: (_) => DailyVerseScreen(
        textId: textId,
        title: title,
        targetLocalDate: now,
      ),
    );

    if (replaceStack) {
      navigator.pushAndRemoveUntil(route, (r) => false);
    } else {
      navigator.push(route);
    }
  }
}
