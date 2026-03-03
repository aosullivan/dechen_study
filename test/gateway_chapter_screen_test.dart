import 'package:dechen_study/screens/landing/gateway_chapter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Color _leadingIconColorForLabel(WidgetTester tester, String label) {
  final textFinder = find.text(label);
  expect(textFinder, findsWidgets);
  final rowFinder =
      find.ancestor(of: textFinder.first, matching: find.byType(Row)).first;
  final iconFinder =
      find.descendant(of: rowFinder, matching: find.byType(Icon)).first;
  final icon = tester.widget<Icon>(iconFinder);
  expect(icon.color, isNotNull);
  return icon.color!;
}

void main() {
  testWidgets('chapter 1 renders rich aggregate chips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Five Aggregates'), findsWidgets);
    expect(find.text('Consciousness'), findsWidgets);
    expect(find.text('Aggregate of Form'), findsWidgets);
  });

  testWidgets('chapter 2 renders consciousness element list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 2),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        RegExp(r'Six Sense Triads at a Glance|Eighteen Dhatus'),
      ),
      findsWidgets,
    );
    expect(find.text('Eye Consciousness Element'), findsWidgets);
    expect(find.text('Mind Consciousness Element'), findsWidgets);
  });

  testWidgets('chapter 3 mapping uses consistent source/dhatu colors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 3),
      ),
    );
    await tester.pumpAndSettle();

    // Source-side consistency (Ayatanas): inner sources are green, outer sources are blue.
    expect(_leadingIconColorForLabel(tester, 'Eye Source'),
        const Color(0xFF2E7D52));
    expect(_leadingIconColorForLabel(tester, 'Visual Object Source'),
        const Color(0xFF2C5F8A));

    // Dhatu-side consistency: faculties yellow, objects orange, consciousnesses white.
    expect(_leadingIconColorForLabel(tester, 'Eye Element'),
        const Color(0xFF7A6000));
    expect(_leadingIconColorForLabel(tester, 'Visual Form Element'),
        const Color(0xFF96490A));
    expect(_leadingIconColorForLabel(tester, 'Eye Consciousness Element'),
        const Color(0xFF8B7355));
  });
}
