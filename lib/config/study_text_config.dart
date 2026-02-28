/// Configuration for a study text.
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
    this.sectionCluesPath,
    this.quizBeginnerPath,
    this.quizAdvancedPath,
    this.guessChapterEnabled = true,
    this.purchaseRootTextUrl,
    this.purchaseCommentaryUrl,
    this.purchaseRootTextSearchTerm,
    this.purchaseCommentarySearchTerm,
    this.hasChapters = true,
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
  final String? sectionCluesPath;
  final String? quizBeginnerPath;
  final String? quizAdvancedPath;
  final bool guessChapterEnabled;
  final String? purchaseRootTextUrl;
  final String? purchaseCommentaryUrl;
  final String? purchaseRootTextSearchTerm;
  final String? purchaseCommentarySearchTerm;
  final bool hasChapters;

  /// Core data needed for daily/read/overview flows.
  bool get hasCoreStudySupport =>
      parsedJsonPath.isNotEmpty &&
      hierarchyPath.isNotEmpty &&
      commentaryPath.isNotEmpty;

  /// Quiz data availability.
  bool get hasQuizSupport =>
      quizBeginnerPath != null && quizBeginnerPath!.isNotEmpty;

  /// Returns whether a specific study mode is supported for this text.
  bool supportsMode(String mode) {
    switch (mode) {
      case 'daily':
      case 'read':
      case 'overview':
        return hasCoreStudySupport;
      case 'guess_chapter':
        return hasQuizSupport && guessChapterEnabled;
      case 'quiz':
        return hasQuizSupport;
      default:
        return false;
    }
  }

  /// Legacy "full support" (daily/read/overview + guess chapter + quiz).
  bool get hasFullStudySupport =>
      hasCoreStudySupport && hasQuizSupport && guessChapterEnabled;
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
  const StudyTextConfig(
    textId: 'kingofaspirations',
    title: 'The King of Aspiration Prayers',
    path: '/kingofaspirations',
    author: 'SAMANTABHADRA',
    description:
        'Daily verses, read mode, and structural overview for Samantabhadra’s Aspiration to Good Actions. The structure is based on the commentary written by Drakpa Gyaltsen, a student of Jamyang Khyentse Wangpo.',
    coverAssetPath: 'assets/kingofaspirations.webp',
    parsedJsonPath: 'texts/kingofaspirations/koa_parsed.json',
    hierarchyPath: 'texts/kingofaspirations/verse_hierarchy_map.json',
    commentaryPath: 'texts/kingofaspirations/verse_commentary_mapping.txt',
    hasChapters: false,
  ),
  const StudyTextConfig(
    textId: 'friendlyletter',
    title: 'Friendly Letter',
    path: '/friendlyletter',
    author: 'NAGARJUNA',
    description:
        'Daily verses, read mode, and structural overview for The Letter to a Friend (Suhrillekha), mapped to the hierarchy used in The Telescope of Wisdom commentary, composed by Karma Thinley Rinpoche.',
    coverAssetPath: 'assets/friendlyletter.jpg',
    parsedJsonPath: 'texts/friendlyletter/friendlyletter_parsed.json',
    hierarchyPath: 'texts/friendlyletter/verse_hierarchy_map.json',
    commentaryPath: 'texts/friendlyletter/verse_commentary_mapping.txt',
    quizBeginnerPath: 'texts/friendlyletter/root_text_quiz.txt',
    guessChapterEnabled: false,
    hasChapters: false,
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

/// Returns all study texts with core support (daily/read/overview).
List<StudyTextConfig> getStudyTextsWithCoreSupport() {
  return studyTextRegistry.where((c) => c.hasCoreStudySupport).toList();
}

/// Returns true if [textId] has core support.
bool hasCoreStudySupport(String textId) {
  return getStudyText(textId)?.hasCoreStudySupport ?? false;
}

/// Returns true if [textId] has full study support (all five buttons work).
bool hasFullStudySupport(String textId) {
  return getStudyText(textId)?.hasFullStudySupport ?? false;
}

/// Returns true if [mode] is supported for [textId].
bool supportsStudyMode(String textId, String mode) {
  return getStudyText(textId)?.supportsMode(mode) ?? false;
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
