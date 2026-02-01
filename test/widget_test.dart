// Basic Flutter widget test for the study app.
// Verifies that the app builds and navigates to landing after splash (no pending timers).

import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/main.dart';
import 'package:dechen_study/screens/landing/landing_screen.dart';

void main() {
  testWidgets('App builds and shows landing after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Advance past splash delay (1s) so redirect runs and timer is not pending
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // kDebugMode skips login and goes to LandingScreen
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('Bodhicaryavatara'), findsOneWidget);
  });
}
