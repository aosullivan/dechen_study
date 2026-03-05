import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/study_text_config.dart';
import '../../services/app_preferences_service.dart';
import '../../services/daily_notification_service.dart';
import '../../services/daily_verse_picker_service.dart';
import '../../utils/web_navigation.dart';
import '../landing/daily_verse_screen.dart';
import '../landing/gateway_landing_screen.dart';
import '../landing/landing_screen.dart';
import '../landing/text_options_screen.dart';
import '../mobile/mobile_home_screen.dart';
import '../mobile/mobile_text_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (!kIsWeb) {
      await _redirectMobile();
      return;
    }

    _redirectWeb();
  }

  Future<void> _redirectMobile() async {
    final prefs = await AppPreferencesService.instance.load();
    if (!mounted) return;

    if (!prefs.onboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MobileTextSelectionScreen()),
      );
      return;
    }

    final pendingIntent =
        DailyNotificationService.instance.takePendingLaunchIntent();
    if (pendingIntent?.type == DailyNotificationIntentType.dailyVerse) {
      final now = DateTime.now();
      final textId = DailyVersePickerService.instance.pickDailyTextId(
        now,
        prefs.selectedTextIds,
      );
      if (textId != null) {
        final title = getStudyText(textId)?.title ?? 'Daily verses';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DailyVerseScreen(
              textId: textId,
              title: title,
              targetLocalDate: now,
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MobileHomeScreen(showDailySettingsPrompt: true),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MobileHomeScreen()),
    );
  }

  void _redirectWeb() {
    final path = currentAppPath();

    final studyText = getStudyTextByPath(path);
    if (studyText != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TextOptionsScreen(
            textId: studyText.textId,
            title: studyText.title,
          ),
        ),
      );
      return;
    }

    if (path == '/gateway-to-knowledge' ||
        path.startsWith('/gateway-to-knowledge/chapter-')) {
      final chapterNumber = _parseGatewayChapter(path);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GatewayLandingScreen(
            initialChapterNumber: chapterNumber,
          ),
        ),
      );
      return;
    }

    // Skip login for now - go straight to landing (re-enable session check to require login)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
    );
  }

  int? _parseGatewayChapter(String path) {
    final match = RegExp(r'^/gateway-to-knowledge/chapter-(\d+)$')
        .firstMatch(path.trim());
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Study',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
