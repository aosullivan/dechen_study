import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/splash_screen.dart';
import 'services/app_preferences_service.dart';
import 'services/daily_notification_navigation.dart';
import 'services/daily_notification_service.dart';
import 'services/usage_metrics_service.dart';
import 'utils/app_navigation.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

final _usageMetricsLifecycleObserver = _UsageMetricsLifecycleObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load fallback environment variables from asset.
    // Per-environment overrides can be passed via --dart-define.
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv load skipped: $e');
  }

  try {
    if (isSupabaseConfigured) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      await UsageMetricsService.instance.init();
    } else {
      debugPrint(
        'Supabase not configured for APP_ENV=$appEnvironment; running without backend analytics.',
      );
    }
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    // Continue anyway - the app will still run without Supabase-backed features.
  }

  WidgetsBinding.instance.addObserver(_usageMetricsLifecycleObserver);
  await DailyNotificationService.instance.init();
  if (!kIsWeb) {
    final preferences = await AppPreferencesService.instance.load();
    await DailyNotificationService.instance.applySchedule(preferences);
  }
  DailyNotificationService.instance.intentStream.listen((intent) {
    if (intent.type == DailyNotificationIntentType.dailyVerse && !kIsWeb) {
      unawaited(
        DailyNotificationNavigation.openTodayFromNotification(
          replaceStack: false,
        ),
      );
    }
  });

  runApp(const MyApp());
}

class _UsageMetricsLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(UsageMetricsService.instance.onAppLifecycleStateChanged(state));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool _useDesktopLightMode() {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Dechen Study',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _useDesktopLightMode() ? ThemeMode.light : ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
