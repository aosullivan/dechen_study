import 'package:flutter/material.dart';

import '../landing/landing_screen.dart';

/// Legacy entrypoint kept for compatibility.
/// The app now uses the unified landing flow to avoid duplicated navigation stacks.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingScreen();
  }
}
