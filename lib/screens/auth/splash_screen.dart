import 'package:flutter/material.dart';

import '../landing/landing_screen.dart';
import '../landing/text_options_screen.dart';
import '../../utils/web_navigation.dart';

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

    if (currentAppPath() == '/bodhicaryavatara') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const TextOptionsScreen(
            textId: 'bodhicaryavatara',
            title: 'Bodhicaryavatara',
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
