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
}
