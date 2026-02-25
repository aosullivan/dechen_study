import 'package:dechen_study/screens/landing/guess_chapter_screen.dart';
import 'package:dechen_study/screens/landing/read_screen.dart';
import 'package:dechen_study/screens/landing/daily_verse_screen.dart';
import 'package:dechen_study/screens/landing/textual_overview_screen.dart';
import 'package:dechen_study/services/usage_metrics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = UsageMetricsService.instance;

  setUp(() {
    service.resetForTesting();
  });

  tearDown(() async {
    await service.flush(all: true);
    service.resetForTesting();
  });

  Future<List<Map<String, dynamic>>> collectSurfaceDwellFromDispose(
    WidgetTester tester,
    Widget child,
  ) async {
    final insertedRows = <Map<String, dynamic>>[];
    service.configureForTesting(
      enabled: true,
      initialized: true,
      anonId: 'anon_screen_smoke',
      minDwellMs: 0,
      disableAutoFlush: true,
      insertBatch: (batch) async {
        insertedRows.addAll(batch.map((row) => Map<String, dynamic>.from(row)));
      },
      currentUserId: () => null,
    );

    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    await service.flush(all: true);
    await tester.pump();

    return insertedRows
        .where((row) => row['event_name'] == 'surface_dwell')
        .toList();
  }

  testWidgets('read screen emits surface dwell on dispose', (tester) async {
    final events = await collectSurfaceDwellFromDispose(
      tester,
      const ReadScreen(
        textId: 'bodhicaryavatara',
        title: 'Bodhicaryavatara',
      ),
    );

    expect(events.any((row) => row['mode'] == 'read'), isTrue);
  });

  testWidgets('daily screen emits surface dwell on dispose', (tester) async {
    final events = await collectSurfaceDwellFromDispose(
      tester,
      const DailyVerseScreen(
        textId: 'bodhicaryavatara',
        title: 'Bodhicaryavatara',
      ),
    );

    expect(events.any((row) => row['mode'] == 'daily'), isTrue);
  });

  testWidgets('guess-chapter screen emits surface dwell on dispose',
      (tester) async {
    final events = await collectSurfaceDwellFromDispose(
      tester,
      const GuessChapterScreen(
        textId: 'bodhicaryavatara',
        title: 'Bodhicaryavatara',
      ),
    );

    expect(events.any((row) => row['mode'] == 'guess_chapter'), isTrue);
  });

  testWidgets('overview screen emits surface dwell on dispose', (tester) async {
    final events = await collectSurfaceDwellFromDispose(
      tester,
      const TextualOverviewScreen(
        textId: 'bodhicaryavatara',
        title: 'Bodhicaryavatara',
      ),
    );

    expect(events.any((row) => row['mode'] == 'overview'), isTrue);
  });
}
