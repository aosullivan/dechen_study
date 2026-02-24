import 'package:dechen_study/screens/landing/landing_screen.dart';
import 'package:dechen_study/screens/landing/text_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping Bodhicaryavatara opens text options screen',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LandingScreen(),
      ),
    );

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(TextOptionsScreen), findsNothing);

    await tester.tap(find.text('Bodhicaryavatara').first);
    await tester.pumpAndSettle();

    expect(find.byType(TextOptionsScreen), findsOneWidget);
    expect(find.text('Bodhicaryavatara'), findsWidgets);
    expect(find.text('Root Text'), findsOneWidget);
    expect(find.text('Guess the Chapter'), findsOneWidget);
  });
}
