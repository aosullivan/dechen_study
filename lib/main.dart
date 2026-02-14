import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables (included in assets via pubspec.yaml)
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    // Continue anyway - the app will show an error screen
  }

  runApp(const MyApp());
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
          seedColor: const Color(0xFF8B7355), // Warm brown
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8F5), // Warm off-white
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Crimson Text',
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2416),
          ),
          displayMedium: TextStyle(
            fontFamily: 'Crimson Text',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2416),
          ),
          titleLarge: TextStyle(
            fontFamily: 'Crimson Text',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2416),
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Lora',
            fontSize: 16,
            height: 1.8,
            color: Color(0xFF3D3426),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Lora',
            fontSize: 14,
            height: 1.7,
            color: Color(0xFF3D3426),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B7355),
            foregroundColor: const Color(0xFFFAF8F5),
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
            borderSide: const BorderSide(color: Color(0xFFD4C4B0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD4C4B0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF8B7355), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
