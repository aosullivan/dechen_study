import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/usage_metrics_service.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

final _usageMetricsLifecycleObserver = _UsageMetricsLifecycleObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables (included in assets via pubspec.yaml)
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    await UsageMetricsService.instance.init();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    // Continue anyway - the app will show an error screen
  }

  WidgetsBinding.instance.addObserver(_usageMetricsLifecycleObserver);

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dechen Study',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Lora',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Crimson Text',
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Crimson Text',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Crimson Text',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Lora',
            fontSize: 16,
            height: 1.8,
            color: AppColors.bodyText,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Lora',
            fontSize: 14,
            height: 1.7,
            color: AppColors.bodyText,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.scaffoldBackground,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
