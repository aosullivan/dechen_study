/// Configuration for a study text (full five-mode support: Daily, Quiz, Read, etc.).
class StudyTextConfig {
  const StudyTextConfig({
    required this.textId,
    required this.title,
    required this.path,
    required this.author,
    this.description,
    this.coverAssetPath,
    required this.parsedJsonPath,
    required this.hierarchyPath,
    required this.commentaryPath,
    required this.sectionCluesPath,
    this.quizBeginnerPath,
    this.quizAdvancedPath,
    this.purchaseRootTextUrl,
    this.purchaseCommentaryUrl,
    this.purchaseRootTextSearchTerm,
    this.purchaseCommentarySearchTerm,
  });

  final String textId;
  final String title;
  final String path;
  final String author;
  final String? description;
  final String? coverAssetPath;
  final String parsedJsonPath;
  final String hierarchyPath;
  final String commentaryPath;
  final String sectionCluesPath;
  final String? quizBeginnerPath;
  final String? quizAdvancedPath;
  final String? purchaseRootTextUrl;
  final String? purchaseCommentaryUrl;
  final String? purchaseRootTextSearchTerm;
  final String? purchaseCommentarySearchTerm;

  /// True when all required data assets are present for the five study modes.
  bool get hasFullStudySupport =>
      parsedJsonPath.isNotEmpty &&
      hierarchyPath.isNotEmpty &&
      commentaryPath.isNotEmpty &&
      sectionCluesPath.isNotEmpty &&
      (quizBeginnerPath != null && quizBeginnerPath!.isNotEmpty);
}

/// Registry of study texts. Add a new text by appending a [StudyTextConfig] and
/// adding the corresponding data files + pubspec assets.
final List<StudyTextConfig> studyTextRegistry = [
  const StudyTextConfig(
    textId: 'bodhicaryavatara',
    title: 'Bodhicaryavatara',
    path: '/bodhicaryavatara',
    author: 'SANTIDEVA',
    description:
        'Read, explore the root text, reflect with daily verses, and quiz yourself. The root text is presented in a structured format according to the commentary by Sonam Tsemo.',
    coverAssetPath: 'assets/bodhicarya.jpg',
    parsedJsonPath: 'texts/bodhicaryavatara/bcv_parsed.json',
    hierarchyPath: 'texts/bodhicaryavatara/verse_hierarchy_map.json',
    commentaryPath: 'texts/bodhicaryavatara/verse_commentary_mapping.txt',
    sectionCluesPath: 'texts/bodhicaryavatara/section_clues.json',
    quizBeginnerPath: 'texts/bodhicaryavatara/root_text_quiz.txt',
    quizAdvancedPath: 'texts/bodhicaryavatara/root_text_quiz_400.txt',
    purchaseRootTextUrl: 'https://amzn.to/3N1bxAD',
    purchaseCommentaryUrl: 'https://amzn.to/3MsRxa5',
    purchaseRootTextSearchTerm: 'Bodhicaryavatara Santideva root text',
    purchaseCommentarySearchTerm: 'Bodhicaryavatara Sonam Tsemo commentary',
  ),
];

/// Returns the config for [textId], or null if not found.
StudyTextConfig? getStudyText(String textId) {
  try {
    return studyTextRegistry.firstWhere((c) => c.textId == textId);
  } catch (_) {
    return null;
  }
}

/// Returns all study texts that have full five-mode support.
List<StudyTextConfig> getStudyTextsWithFullSupport() {
  return studyTextRegistry.where((c) => c.hasFullStudySupport).toList();
}

/// Returns true if [textId] has full study support (all five buttons work).
bool hasFullStudySupport(String textId) {
  return getStudyText(textId)?.hasFullStudySupport ?? false;
}

/// Returns the study text whose [path] matches [path], or null.
StudyTextConfig? getStudyTextByPath(String path) {
  final normalized = path.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  try {
    return studyTextRegistry.firstWhere(
      (c) => c.path.toLowerCase() == normalized,
    );
  } catch (_) {
    return null;
  }
}
