import 'package:dechen_study/screens/landing/landing_screen.dart';
import 'package:dechen_study/screens/landing/text_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('landing shows The King of Aspiration Prayers card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LandingScreen(),
      ),
    );

    expect(find.text('The King of Aspiration Prayers'), findsOneWidget);
  });

  testWidgets(
    'KOA options show Daily/Read/Textual Structure only (no quiz modes)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TextOptionsScreen(
            textId: 'kingofaspirations',
            title: 'The King of Aspiration Prayers',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Daily Verses'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Textual Structure'), findsOneWidget);

      expect(find.text('Guess the Chapter'), findsNothing);
      expect(find.text('Quiz'), findsNothing);
    },
  );
}
