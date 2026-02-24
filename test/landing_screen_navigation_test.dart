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
    expect(find.text('Guess the Chapter'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Purchase root text'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Purchase root text'), findsOneWidget);
  });

  testWidgets('tapping Bodhicaryavatara cover image opens read flow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LandingScreen(),
      ),
    );

    await tester.tap(find.text('Bodhicaryavatara').first);
    await tester.pumpAndSettle();

    final coverImageFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/bodhicarya.jpg',
    );
    expect(coverImageFinder, findsOneWidget);

    final coverTapTarget = find
        .ancestor(of: coverImageFinder, matching: find.byType(InkWell))
        .first;
    await tester.tap(coverTapTarget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TextOptionsScreen), findsNothing);
    expect(find.text('Guess the Chapter'), findsNothing);
  });
}
