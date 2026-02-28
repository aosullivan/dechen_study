import 'package:dechen_study/screens/landing/overview/overview_node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('book icon is hidden when showBookIcon is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverviewNodeCard(
            path: '1',
            title: 'Section title',
            depth: 0,
            hasChildren: false,
            isExpanded: false,
            isSelected: false,
            onTap: () {},
            onBookTap: () {},
            showBookIcon: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.menu_book_rounded), findsNothing);
  });

  testWidgets('book icon is shown when showBookIcon is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverviewNodeCard(
            path: '1',
            title: 'Section title',
            depth: 0,
            hasChildren: false,
            isExpanded: false,
            isSelected: false,
            onTap: () {},
            onBookTap: () {},
            showBookIcon: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
  });
}
