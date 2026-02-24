import 'package:flutter/material.dart';

import '../landing/gateway_landing_screen.dart';
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

    final path = currentAppPath();

    if (path == '/bodhicaryavatara') {
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
