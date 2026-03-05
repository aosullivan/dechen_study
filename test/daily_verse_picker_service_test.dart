import 'package:dechen_study/services/daily_verse_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = DailyVersePickerService.instance;

  test('pickDailyTextId is deterministic for same date and set', () {
    const selected = <String>{
      'gateway_to_knowledge',
      'bodhicaryavatara',
      'friendlyletter'
    };
    final date = DateTime(2026, 3, 5);

    final first = service.pickDailyTextId(date, selected);
    final second = service.pickDailyTextId(date, selected);

    expect(first, isNotNull);
    expect(second, first);
    expect(first, isNot('gateway_to_knowledge'));
  });

  test('pickDailyTextId rotates across dates for same selection', () {
    const selected = <String>{
      'bodhicaryavatara',
      'friendlyletter',
      'lampofthepath'
    };
    final first = service.pickDailyTextId(DateTime(2026, 3, 5), selected);
    final upcoming = List<String?>.generate(
      7,
      (index) =>
          service.pickDailyTextId(DateTime(2026, 3, 6 + index), selected),
    );

    expect(first, isNotNull);
    expect(upcoming.whereType<String>(), isNotEmpty);
    expect(upcoming.any((candidate) => candidate != first), isTrue,
        reason: 'Daily choice should rotate by date for subscribed texts.');
  });

  test('pickDailyTextId returns null when only gateway selected', () {
    final selected = <String>{'gateway_to_knowledge'};
    final picked = service.pickDailyTextId(DateTime(2026, 3, 5), selected);
    expect(picked, isNull);
  });

  test('pickDailySection returns deterministic section for a date', () async {
    final date = DateTime(2026, 3, 5);
    final first = await service.pickDailySection('bodhicaryavatara', date);
    final second = await service.pickDailySection('bodhicaryavatara', date);

    expect(first?.refsInBlock, second?.refsInBlock);
  });
}
