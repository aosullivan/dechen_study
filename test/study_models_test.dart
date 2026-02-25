import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/models/study_models.dart';

void main() {
  group('Section', () {
    test('fromJson parses valid payload', () {
      final json = {
        'id': 'sec-1',
        'chapter_id': 'ch-1',
        'chapter_number': 1,
        'text': 'Section text',
      };
      final section = Section.fromJson(json);
      expect(section.id, 'sec-1');
      expect(section.chapterId, 'ch-1');
      expect(section.chapterNumber, 1);
      expect(section.text, 'Section text');
    });

    test('toJson returns correct map', () {
      final section = Section(
        id: 'sec-1',
        chapterId: 'ch-1',
        chapterNumber: 1,
        text: 'Section text',
      );
      final json = section.toJson();
      expect(json['id'], 'sec-1');
      expect(json['chapter_id'], 'ch-1');
      expect(json['chapter_number'], 1);
      expect(json['text'], 'Section text');
    });

    test('fromJson throws FormatException when key is missing', () {
      final json = {
        'id': 'sec-1',
        'chapter_id': 'ch-1',
        // missing chapter_number and text
      };
      expect(() => Section.fromJson(json), throwsFormatException);
    });

    test('fromJson throws on wrong type for chapter_number', () {
      final json = {
        'id': 'sec-1',
        'chapter_id': 'ch-1',
        'chapter_number': 'one', // should be int
        'text': 'Section text',
      };
      expect(() => Section.fromJson(json), throwsA(anything));
    });
  });

  group('Chapter', () {
    test('fromJson parses valid payload with sections', () {
      final json = {
        'id': 'ch-1',
        'number': 1,
        'title': 'Chapter One',
        'sections': [
          {
            'id': 'sec-1',
            'chapter_id': 'ch-1',
            'chapter_number': 1,
            'text': 'Section 1',
          },
        ],
      };
      final chapter = Chapter.fromJson(json);
      expect(chapter.id, 'ch-1');
      expect(chapter.number, 1);
      expect(chapter.title, 'Chapter One');
      expect(chapter.sections.length, 1);
      expect(chapter.sections.first.id, 'sec-1');
    });

    test('toJson returns correct map', () {
      final section = Section(
        id: 'sec-1',
        chapterId: 'ch-1',
        chapterNumber: 1,
        text: 'Section text',
      );
      final chapter = Chapter(
        id: 'ch-1',
        number: 1,
        title: 'Chapter One',
        sections: [section],
      );
      final json = chapter.toJson();
      expect(json['id'], 'ch-1');
      expect(json['number'], 1);
      expect(json['title'], 'Chapter One');
      expect(json['sections'], isA<List>());
      expect((json['sections'] as List).length, 1);
    });

    test('fromJson throws when sections key is missing', () {
      final json = {
        'id': 'ch-1',
        'number': 1,
        'title': 'Chapter One',
      };
      expect(() => Chapter.fromJson(json), throwsFormatException);
    });
  });

  group('StudyText', () {
    test('fromJson parses valid payload with chapters', () {
      final json = {
        'id': 'text-1',
        'title': 'Study Text',
        'full_text': 'Full content',
        'chapters': [
          {
            'id': 'ch-1',
            'number': 1,
            'title': 'Chapter One',
            'sections': [
              {
                'id': 'sec-1',
                'chapter_id': 'ch-1',
                'chapter_number': 1,
                'text': 'Section 1',
              },
            ],
          },
        ],
      };
      final studyText = StudyText.fromJson(json);
      expect(studyText.id, 'text-1');
      expect(studyText.title, 'Study Text');
      expect(studyText.fullText, 'Full content');
      expect(studyText.chapters.length, 1);
      expect(studyText.chapters.first.sections.length, 1);
    });

    test('toJson returns correct map', () {
      final section = Section(
        id: 'sec-1',
        chapterId: 'ch-1',
        chapterNumber: 1,
        text: 'Section text',
      );
      final chapter = Chapter(
        id: 'ch-1',
        number: 1,
        title: 'Chapter One',
        sections: [section],
      );
      final studyText = StudyText(
        id: 'text-1',
        title: 'Study Text',
        fullText: 'Full content',
        chapters: [chapter],
      );
      final json = studyText.toJson();
      expect(json['id'], 'text-1');
      expect(json['title'], 'Study Text');
      expect(json['full_text'], 'Full content');
      expect(json['chapters'], isA<List>());
    });

    test('fromJson throws when full_text key is missing', () {
      final json = {
        'id': 'text-1',
        'title': 'Study Text',
        'chapters': [],
      };
      expect(() => StudyText.fromJson(json), throwsFormatException);
    });
  });

  group('DailySection', () {
    test('fromJson parses valid payload', () {
      final json = {
        'id': 'daily-1',
        'user_id': 'user-1',
        'section_id': 'sec-1',
        'date': '2025-02-25T00:00:00.000',
        'completed': true,
      };
      final daily = DailySection.fromJson(json);
      expect(daily.id, 'daily-1');
      expect(daily.userId, 'user-1');
      expect(daily.sectionId, 'sec-1');
      expect(daily.date, DateTime(2025, 2, 25));
      expect(daily.completed, true);
    });

    test('toJson returns correct map', () {
      final daily = DailySection(
        id: 'daily-1',
        userId: 'user-1',
        sectionId: 'sec-1',
        date: DateTime(2025, 2, 25),
        completed: true,
      );
      final json = daily.toJson();
      expect(json['id'], 'daily-1');
      expect(json['user_id'], 'user-1');
      expect(json['section_id'], 'sec-1');
      expect(json['date'], '2025-02-25T00:00:00.000');
      expect(json['completed'], true);
    });

    test('fromJson throws when completed key is missing', () {
      final json = {
        'id': 'daily-1',
        'user_id': 'user-1',
        'section_id': 'sec-1',
        'date': '2025-02-25T00:00:00.000',
      };
      expect(() => DailySection.fromJson(json), throwsFormatException);
    });

    test('fromJson throws on wrong type for completed', () {
      final json = {
        'id': 'daily-1',
        'user_id': 'user-1',
        'section_id': 'sec-1',
        'date': '2025-02-25T00:00:00.000',
        'completed': 'yes', // should be bool
      };
      expect(() => DailySection.fromJson(json), throwsA(anything));
    });
  });
}
