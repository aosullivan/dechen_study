import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/services/gateway_outline_service.dart';

void main() {
  final service = GatewayOutlineService.instance;

  group('GatewayOutlineService', () {
    test('getChapters returns all chapters', () async {
      final chapters = await service.getChapters();
      expect(chapters.length, 4);
      expect(chapters[0].number, 1);
      expect(chapters[0].title, 'The Aggregates (Skandhas)');
      expect(chapters[1].number, 2);
      expect(chapters[2].number, 3);
      expect(chapters[3].number, 4);
    });

    test('getChapter returns chapter 1 with sections', () async {
      final chapter = await service.getChapter(1);
      expect(chapter, isNotNull);
      expect(chapter!.number, 1);
      expect(chapter.title, 'The Aggregates (Skandhas)');
      expect(chapter.sections.length, 7);
      expect(chapter.sections[0].path, '1.1');
      expect(chapter.sections[0].title, 'Five Aggregates');
      expect(chapter.sections[0].depth, 0);
    });

    test('getChapter returns chapter 2', () async {
      final chapter = await service.getChapter(2);
      expect(chapter, isNotNull);
      expect(chapter!.number, 2);
      expect(chapter.title, 'The Elements (Dhatu)');
      expect(chapter.sections.length, 4);
    });

    test('getChapter returns null for non-existent chapter', () async {
      final chapter = await service.getChapter(99);
      expect(chapter, isNull);
    });

    test('getChapter returns chapter 4', () async {
      final chapter = await service.getChapter(4);
      expect(chapter, isNotNull);
      expect(chapter!.number, 4);
      expect(chapter.title, 'Dependent Origination');
      expect(chapter.sections.length, 7);
    });
  });
}
