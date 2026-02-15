/// Safe JSON extraction helpers for fromJson. Throw [FormatException] on missing/invalid data.
T _require<T>(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) throw FormatException('study_models: missing key "$key"');
  return v as T;
}

String _requireString(Map<String, dynamic> json, String key) =>
    _require<String>(json, key);

int _requireInt(Map<String, dynamic> json, String key) =>
    _require<int>(json, key);

bool _requireBool(Map<String, dynamic> json, String key) =>
    _require<bool>(json, key);

List<dynamic> _requireList(Map<String, dynamic> json, String key) =>
    _require<List<dynamic>>(json, key);

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
      id: _requireString(json, 'id'),
      title: _requireString(json, 'title'),
      fullText: _requireString(json, 'full_text'),
      chapters: _requireList(json, 'chapters')
          .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
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
      id: _requireString(json, 'id'),
      number: _requireInt(json, 'number'),
      title: _requireString(json, 'title'),
      sections: _requireList(json, 'sections')
          .map((s) => Section.fromJson(s as Map<String, dynamic>))
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
      id: _requireString(json, 'id'),
      chapterId: _requireString(json, 'chapter_id'),
      chapterNumber: _requireInt(json, 'chapter_number'),
      text: _requireString(json, 'text'),
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
      id: _requireString(json, 'id'),
      userId: _requireString(json, 'user_id'),
      sectionId: _requireString(json, 'section_id'),
      date: DateTime.parse(_requireString(json, 'date')),
      completed: _requireBool(json, 'completed'),
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
