import 'package:dechen_study/services/usage_metrics_service.dart';
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

  test('batches flushes into chunks of 20 events', () async {
    final insertedBatches = <List<Map<String, dynamic>>>[];

    service.configureForTesting(
      enabled: true,
      initialized: true,
      anonId: 'anon_batch',
      disableAutoFlush: true,
      insertBatch: (batch) async {
        insertedBatches
            .add(batch.map((row) => Map<String, dynamic>.from(row)).toList());
      },
      currentUserId: () => null,
    );

    for (var i = 0; i < 25; i++) {
      await service.trackEvent(
        eventName: 'surface_dwell',
        textId: 'bodhicaryavatara',
        mode: 'read',
        durationMs: 1500,
      );
    }

    expect(service.pendingCount, 25);

    await service.flush();
    expect(insertedBatches.length, 1);
    expect(insertedBatches.first.length, 20);
    expect(service.pendingCount, 5);

    await service.flush(all: true);
    expect(insertedBatches.length, 2);
    expect(insertedBatches[1].length, 5);
    expect(service.pendingCount, 0);
  });

  test('uses anon_id for anonymous actors and user_id for authenticated actors',
      () async {
    final insertedRows = <Map<String, dynamic>>[];

    service.configureForTesting(
      enabled: true,
      initialized: true,
      anonId: 'anon_actor',
      disableAutoFlush: true,
      insertBatch: (batch) async {
        insertedRows.addAll(batch.map((row) => Map<String, dynamic>.from(row)));
      },
      currentUserId: () => null,
    );

    await service.trackEvent(
      eventName: 'text_option_tapped',
      textId: 'bodhicaryavatara',
      mode: 'read',
    );
    await service.flush(all: true);

    expect(insertedRows.length, 1);
    expect(insertedRows.single['user_id'], isNull);
    expect(insertedRows.single['anon_id'], 'anon_actor');

    insertedRows.clear();
    service.resetForTesting();

    service.configureForTesting(
      enabled: true,
      initialized: true,
      anonId: 'anon_actor_should_not_be_used',
      disableAutoFlush: true,
      insertBatch: (batch) async {
        insertedRows.addAll(batch.map((row) => Map<String, dynamic>.from(row)));
      },
      currentUserId: () => '00000000-0000-0000-0000-000000000001',
    );

    await service.trackEvent(
      eventName: 'text_option_tapped',
      textId: 'bodhicaryavatara',
      mode: 'read',
    );
    await service.flush(all: true);

    expect(insertedRows.length, 1);
    expect(
        insertedRows.single['user_id'], '00000000-0000-0000-0000-000000000001');
    expect(insertedRows.single['anon_id'], isNull);
  });

  test('normalizes event fields and ignores blank event names', () async {
    final insertedRows = <Map<String, dynamic>>[];
    final fixedNow = DateTime.utc(2026, 2, 22, 12, 0, 0);

    service.configureForTesting(
      enabled: true,
      initialized: true,
      anonId: 'anon_norm',
      disableAutoFlush: true,
      insertBatch: (batch) async {
        insertedRows.addAll(batch.map((row) => Map<String, dynamic>.from(row)));
      },
      currentUserId: () => null,
      nowUtc: () => fixedNow,
    );

    await service.trackEvent(
      eventName: '   ',
      textId: 'bodhicaryavatara',
      mode: 'read',
    );

    expect(service.pendingCount, 0);

    await service.trackEvent(
      eventName: '  surface_dwell  ',
      textId: '   ',
      mode: '  read ',
      sectionPath: '   ',
      sectionTitle: '  Useful Section  ',
      verseRef: ' 9.2bcd ',
      durationMs: 1500,
      properties: {'sample': true},
    );

    await service.flush(all: true);

    expect(insertedRows.length, 1);
    final row = insertedRows.single;
    expect(row['event_name'], 'surface_dwell');
    expect(row['text_id'], isNull);
    expect(row['mode'], 'read');
    expect(row['section_path'], isNull);
    expect(row['section_title'], 'Useful Section');
    expect(row['verse_ref'], '9.2bcd');
    expect(row['occurred_at'], fixedNow.toIso8601String());
    final properties = row['properties'] as Map<String, dynamic>;
    expect(properties['sample'], isTrue);
    expect(properties['environment'], isNotNull);
  });
}
