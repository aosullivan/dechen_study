import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/services/section_clue_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  final service = SectionClueService.instance;

  group('SectionClueService', () {
    test('getClueForRef returns clue for existing ref', () async {
      final clue = await service.getClueForRef('bodhicaryavatara', '1.1');
      expect(clue, isNotNull);
      expect(clue, isNotEmpty);
      expect(clue, contains('purposes'));
    });

    test('getClueForRef returns clue for ref 1.5', () async {
      final clue = await service.getClueForRef('bodhicaryavatara', '1.5');
      expect(clue, isNotNull);
      expect(clue, contains('bodily'));
    });

    test('getClueForRef returns null for non-existent ref', () async {
      final clue = await service.getClueForRef('bodhicaryavatara', '99.99');
      expect(clue, isNull);
    });

    test('getClueForRef returns null for empty ref', () async {
      final clue = await service.getClueForRef('bodhicaryavatara', '');
      expect(clue, isNull);
    });
  });
}
