class Chapter {
  final int id;
  final int chapterNumber;
  final String title;
  final List<String> sections;

  Chapter({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.sections,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      chapterNumber: json['chapter_number'],
      title: json['title'],
      sections: [], // Sections are loaded separately
    );
  }
}

class Section {
  final int id;
  final int chapterId;
  final String content;
  final int orderIndex;

  Section({
    required this.id,
    required this.chapterId,
    required this.content,
    required this.orderIndex,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      chapterId: json['chapter_id'],
      content: json['content'],
      orderIndex: json['order_index'],
    );
  }
}
