class StudyText {
  final String id;
  final String title;
  final String fullText;
  final List<Chapter> chapters;

  StudyText({
    required this.id,
    required this.title,
    required this.fullText,
    required this.chapters,
  });

  factory StudyText.fromJson(Map<String, dynamic> json) {
    return StudyText(
      id: json['id'],
      title: json['title'],
      fullText: json['full_text'],
      chapters: (json['chapters'] as List)
          .map((c) => Chapter.fromJson(c))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'full_text': fullText,
      'chapters': chapters.map((c) => c.toJson()).toList(),
    };
  }
}

class Chapter {
  final String id;
  final int number;
  final String title;
  final List<Section> sections;

  Chapter({
    required this.id,
    required this.number,
    required this.title,
    required this.sections,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      number: json['number'],
      title: json['title'],
      sections: (json['sections'] as List)
          .map((s) => Section.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }
}

class Section {
  final String id;
  final String chapterId;
  final int chapterNumber;
  final String text;

  Section({
    required this.id,
    required this.chapterId,
    required this.chapterNumber,
    required this.text,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      chapterId: json['chapter_id'],
      chapterNumber: json['chapter_number'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'chapter_number': chapterNumber,
      'text': text,
    };
  }
}

class DailySection {
  final String id;
  final String userId;
  final String sectionId;
  final DateTime date;
  final bool completed;

  DailySection({
    required this.id,
    required this.userId,
    required this.sectionId,
    required this.date,
    required this.completed,
  });

  factory DailySection.fromJson(Map<String, dynamic> json) {
    return DailySection(
      id: json['id'],
      userId: json['user_id'],
      sectionId: json['section_id'],
      date: DateTime.parse(json['date']),
      completed: json['completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'section_id': sectionId,
      'date': date.toIso8601String(),
      'completed': completed,
    };
  }
}
