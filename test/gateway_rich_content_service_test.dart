import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/services/gateway_rich_content_service.dart';

void main() {
  final service = GatewayRichContentService.instance;

  group('GatewayRichContentService', () {
    test('getChapter(1) returns chapter with expected structure', () async {
      final chapter = await service.getChapter(1);
      expect(chapter, isNotNull);
      expect(chapter!.number, 1);
      expect(chapter.title, 'The Aggregates (Skandhas)');
      expect(chapter.topics.length, greaterThanOrEqualTo(5));
      expect(chapter.topics[0].title, 'Five Aggregates');
      expect(chapter.topics[0].blocks, isNotEmpty);
    });

    test('getChapter(1) first topic has chip blocks', () async {
      final chapter = await service.getChapter(1);
      expect(chapter, isNotNull);
      final firstTopic = chapter!.topics.first;
      final chips = firstTopic.blocks.where((b) => b.type == 'chip').toList();
      expect(chips.length, 5);
      expect(chips.any((b) => b.text == 'Form'), true);
      expect(chips.any((b) => b.text == 'Consciousness'), true);
    });

    test('getChapter(2) returns chapter with topics', () async {
      final chapter = await service.getChapter(2);
      expect(chapter, isNotNull);
      expect(chapter!.number, 2);
      expect(chapter.title, 'The Elements (Dhatu)');
      expect(chapter.topics, isNotEmpty);
    });

    test('getChapter returns null for non-existent chapter', () async {
      final chapter = await service.getChapter(99);
      expect(chapter, isNull);
    });
  });
}
