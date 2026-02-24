import 'package:dechen_study/screens/landing/gateway_chapter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chapter 1 renders rich aggregate chips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Five Aggregates'), findsOneWidget);
    expect(find.text('Consciousness'), findsWidgets);
    expect(find.text('Aggregate of Form'), findsOneWidget);
  });

  testWidgets('chapter 2 renders consciousness element list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GatewayChapterScreen(chapterNumber: 2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Six Sense Triads at a Glance'), findsOneWidget);
    expect(find.text('Eye Consciousness Element'), findsOneWidget);
    expect(find.text('Mind Consciousness Element'), findsOneWidget);
  });
}
