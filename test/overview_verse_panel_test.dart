library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/screens/landing/overview/overview_verse_panel.dart';
import 'package:dechen_study/services/verse_service.dart';
import 'package:dechen_study/services/verse_hierarchy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await VerseService.instance.getChapters('bodhicaryavatara');
    await VerseHierarchyService.instance.getHierarchyForVerse('bodhicaryavatara', '1.1');
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    required String sectionPath,
    required String sectionTitle,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverviewVersePanel(
            textId: 'bodhicaryavatara',
            sectionPath: sectionPath,
            sectionTitle: sectionTitle,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('parent section shows only own verse refs (not descendants)',
      (WidgetTester tester) async {
    await pumpPanel(
      tester,
      sectionPath: '4.6.2.1.1.3',
      sectionTitle:
          'The valid cognitions which ascertain those characteristics',
    );

    expect(find.text('Verse 9.2'), findsOneWidget);
    expect(find.text('Verse 9.2bcd'), findsNothing);
    expect(find.text('Verse 9.3ab'), findsNothing);
    expect(find.text('Verse 9.3cd'), findsNothing);
    expect(find.text('Verse 9.4abc'), findsNothing);
    expect(find.text('Verse 9.5'), findsNothing);
  });

  testWidgets('leaf section still shows all own refs',
      (WidgetTester tester) async {
    await pumpPanel(
      tester,
      sectionPath: '4.6.2.1.2.3.2.3',
      sectionTitle: 'A counterobjection',
    );

    expect(find.text('Verse 9.28'), findsOneWidget);
    expect(find.text('Verse 9.29'), findsOneWidget);
    expect(find.text('Verse 9.28cd'), findsNothing);
    expect(find.text('Verse 9.29ab'), findsNothing);
  });
}
