import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'login_screen.dart';
import '../landing/landing_screen.dart';

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

    // In debug mode, skip login and go straight to landing (for local dev)
    if (kDebugMode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
      return;
    }

    try {
      final session = supabase.auth.currentSession;
      if (session != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
        );
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      // If Supabase is not configured, go to login screen
      debugPrint('Auth check error: $e');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
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
            const CircularProgressIndicator(
              color: Color(0xFF8B7355),
            ),
          ],
        ),
      ),
    );
  }
}
