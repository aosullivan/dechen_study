import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/study_destination_catalog.dart';
import 'screens/landing/daily_verse_screen.dart';
import 'screens/landing/file_quiz_screen.dart';
import 'screens/landing/gateway_landing_screen.dart';
import 'screens/landing/guess_chapter_screen.dart';
import 'screens/landing/read_screen.dart';
import 'screens/landing/text_options_screen.dart';
import 'screens/landing/textual_overview_screen.dart';
import 'screens/mobile/mobile_home_screen.dart';
import 'screens/mobile/mobile_text_selection_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/app_preferences_service.dart';
import 'utils/app_theme.dart';

const _scene = String.fromEnvironment(
  'SCREENSHOT_SCENE',
  defaultValue: 'text_options_bcv',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_scene == 'mobile_onboarding') {
    await AppPreferencesService.instance.resetForTest();
  }

  if (_scene == 'mobile_home' || _scene == 'settings') {
    await AppPreferencesService.instance.completeOnboarding({
      gatewayDestinationId,
      'bodhicaryavatara',
      'kingofaspirations',
    });
  }

  if (_scene == 'settings') {
    await AppPreferencesService.instance.setDailyNotificationsEnabled(true);
    await AppPreferencesService.instance.setDailyNotificationMinutesLocal(
      (8 * 60) + 30,
    );
  }

  if (_scene == 'overview_bcv') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'bodhicaryavatara_textual_structure_last_path',
      '4.6.2.1.2',
    );
  }

  runApp(const _ScreenshotApp());
}

class _ScreenshotApp extends StatelessWidget {
  const _ScreenshotApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.lightTheme(),
      themeMode: ThemeMode.light,
      home: _homeForScene(),
    );
  }

  Widget _homeForScene() {
    switch (_scene) {
      case 'read_bcv':
        return const ReadScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
          initialChapterNumber: 1,
        );
      case 'quiz_bcv':
        return const FileQuizScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
        );
      case 'guess_bcv':
        return const GuessChapterScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
        );
      case 'gateway_landing':
        return const GatewayLandingScreen();
      case 'daily_koa':
        return const DailyVerseScreen(
          textId: 'kingofaspirations',
          title: 'The King of Aspiration Prayers',
        );
      case 'overview_bcv':
        return const TextualOverviewScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
        );
      case 'mobile_onboarding':
        return const MobileTextSelectionScreen();
      case 'mobile_home':
        return const MobileHomeScreen();
      case 'settings':
        return const SettingsScreen();
      case 'text_options_bcv':
      default:
        return const TextOptionsScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
        );
    }
  }
}
