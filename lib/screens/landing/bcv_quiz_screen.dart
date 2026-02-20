import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../services/bcv_verse_service.dart';
import '../../services/commentary_service.dart';
import 'bcv/bcv_verse_text.dart';

/// Quiz: guess which chapter a random section belongs to. Uses BCV assets.
class BcvQuizScreen extends StatefulWidget {
  const BcvQuizScreen({super.key});

  @override
  State<BcvQuizScreen> createState() => _BcvQuizScreenState();
}

class _BcvQuizScreenState extends State<BcvQuizScreen> {
  final _verseService = BcvVerseService.instance;
  final _commentaryService = CommentaryService.instance;

  bool _isLoading = true;
  List<String> _sectionRefs = [];
  List<String> _sectionVerseTexts = [];
  int _correctChapterNumber = 0;
  String? _correctVerseRef;
  List<BcvChapter> _chapters = [];
  int? _selectedChapter;
  bool _showAnswer = false;
  bool _showChapterLabels = false;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _consecutiveCorrect = 0;
  Object? _error;
  late ConfettiController _confettiController;

  static final _correctAnswerMessages = [
    'Well done! That\'s correct.',
    'Brilliant! Spot on.',
    'Exactly right!',
    'Nice one! Correct.',
    'You got it!',
    'Perfect! Well done.',
    'Spot on! Good job.',
    'Correct! Nice work.',
    'That\'s right! Well done.',
    'Good job! You got it.',
    'Right on!',
    'Correct! Brilliant.',
    'Lovely! That\'s right.',
    'You nailed it!',
    'Right answer! Keep it up.',
    'Correct! Nice going.',
    'Well done! You\'re on fire.',
    'That\'s the one!',
    'Perfect! You know your stuff.',
    'Correct! Splendid.',
    'Right! Good show.',
    'You got it! Well done.',
    'Spot on! Lovely.',
    'Correct! That\'s the ticket.',
  ];
  static final _milestone3Messages = [
    'Three in a row! You\'re on a roll!',
    'Three consecutive! Brilliant streak!',
    'Hat-trick! Well done!',
  ];
  static final _milestone5Messages = [
    'Five in a row! Fantastic!',
    'Five straight! You\'re unstoppable!',
    'Brilliant run! Five correct!',
  ];
  static final _milestone10Messages = [
    'Ten in a row! Incredible!',
    'Double digits! Outstanding!',
    'Ten straight! You\'re a star!',
  ];
  static final _wrongAnswerTemplates = [
    'Not quite. It was %s.',
    'Close! It was actually %s.',
    'Good try. The answer was %s.',
    'Not this time. It was %s.',
    'Keep going! It was %s.',
    'Almost there. It was %s.',
    'Nice effort. It was %s.',
    'You\'ll get the next one. It was %s.',
    'No worries—it was %s.',
    'That\'s a tricky one. It was %s.',
    'Try again next round. It was %s.',
    'Learning moment! It was %s.',
    'Good attempt. It was %s.',
    'Not quite right. It was %s.',
    'So close. It was %s.',
    'Keep studying—it was %s.',
    'Different chapter this time. It was %s.',
    'On the right track. It was %s.',
    'That one was %s.',
    'A bit off. It was %s.',
    'No problem. It was %s.',
    'Brush up and try again. It was %s.',
    'Almost! It was %s.',
    'Wrong chapter. It was %s.',
    'Better luck next time. It was %s.',
  ];
  static const Map<int, String> _shortChapterTitles = {
    1: 'Praise',
    2: 'Confession',
    3: 'Bodhicitta',
    5: 'Clear\nComprehension',
  };

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadQuiz();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _sectionRefs = [];
      _sectionVerseTexts = [];
      _correctChapterNumber = 0;
      _selectedChapter = null;
      _showAnswer = false;
    });
    try {
      final chapters = await _verseService.getChapters();
      final section = await _pickRenderableSection();
      if (section == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'No renderable sections available';
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _sectionRefs = section.refs;
          _sectionVerseTexts = section.verseTexts;
          _correctChapterNumber = section.chapterNumber;
          _correctVerseRef = section.verseRef;
          _chapters = chapters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e;
        });
      }
    }
  }

  Future<_QuizSectionData?> _pickRenderableSection() async {
    for (var attempt = 0; attempt < 40; attempt++) {
      final section = await _commentaryService.getRandomSection();
      if (section == null || section.refsInBlock.isEmpty) continue;
      final data = _buildSectionData(section);
      if (data != null) return data;
    }
    return null;
  }

  _QuizSectionData? _buildSectionData(CommentaryEntry section) {
    final normalizedRefs = _normalizeWholeVerseRefs(section.refsInBlock);
    if (normalizedRefs.isEmpty) return null;

    final refs = <String>[];
    final texts = <String>[];
    for (final ref in normalizedRefs) {
      final idx = _verseService.getIndexForRef(ref);
      if (idx == null) continue;
      final text = _verseService.getVerseAt(idx);
      if (text == null || text.trim().isEmpty) continue;
      refs.add(ref);
      texts.add(text);
    }
    if (refs.isEmpty) return null;

    final chapterNumber = int.tryParse(refs.first.split('.').first);
    if (chapterNumber == null) return null;
    final sameChapter = refs.every((r) => r.startsWith('$chapterNumber.'));
    if (!sameChapter) return null;

    return _QuizSectionData(
      refs: refs,
      verseTexts: texts,
      chapterNumber: chapterNumber,
    );
  }

  List<String> _normalizeWholeVerseRefs(List<String> refsInBlock) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final ref in refsInBlock) {
      final baseRef = ref.replaceAll(BcvVerseService.segmentSuffixPattern, '');
      if (!BcvVerseService.baseVerseRefPattern.hasMatch(baseRef)) continue;
      if (!seen.add(baseRef)) continue;
      normalized.add(baseRef);
    }
    return normalized;
  }

  String _formattedAnswer(BcvChapter chapter, String? verseRef) {
    final verse = verseRef?.trim();
    if (verse == null || verse.isEmpty) {
      return 'Chapter ${chapter.number}: ${chapter.title}';
    }
    return 'Chapter ${chapter.number}: ${chapter.title} - verse $verse';
  }

  String _displayChapterTitle(BcvChapter chapter) {
    return _shortChapterTitles[chapter.number] ?? chapter.title;
  }

  Widget _buildChapterPadKey({
    required BuildContext context,
    required BcvChapter chapter,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required bool showLabel,
  }) {
    final textColor = isCorrect
        ? Colors.green.shade800
        : (isWrong ? AppColors.wrong : AppColors.textDark);
    final label = _displayChapterTitle(chapter);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAnswer ? null : () => _selectChapter(chapter),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withValues(alpha: 0.14)
                : (isWrong
                    ? AppColors.wrong.withValues(alpha: 0.12)
                    : (isSelected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.white)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect
                  ? Colors.green
                  : (isWrong ? AppColors.wrong : AppColors.border),
              width: isCorrect || isWrong ? 1.8 : 1,
            ),
          ),
          child: showLabel
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chapter.number}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  height: 1.0,
                                ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10.5,
                            height: 1.05,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    '${chapter.number}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.0,
                        ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActionPadKey({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool filled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: filled ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        color: filled ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Star path for confetti particles (5-pointed star centered in [size]).
  static Path _createStarPath(Size size) {
    const points = 5;
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide / 2;
    final innerR = outerR * 0.4;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerR : innerR;
      final angle = (i * (pi / points)) - (pi / 2);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _nextQuestion() {
    _loadQuiz();
  }

  void _revealAnswer() {
    if (_showAnswer) return;
    final correctChapter =
        _chapters.firstWhere((c) => c.number == _correctChapterNumber);
    final formattedAnswer = _formattedAnswer(correctChapter, _correctVerseRef);
    final message = 'Answer: $formattedAnswer.';
    setState(() {
      _showAnswer = true;
      _selectedChapter = null;
    });
    _showAnswerDialog(
      message: message,
      title: 'Answer',
      tint: AppColors.primary,
      icon: Icons.info_outline,
    );
  }

  void _selectChapter(BcvChapter chapter) {
    if (_showAnswer) return;
    final correct = chapter.number == _correctChapterNumber;
    String? wrongMsg;
    String? correctMsg;
    final correctChapter =
        _chapters.firstWhere((c) => c.number == _correctChapterNumber);
    final formattedAnswer = _formattedAnswer(correctChapter, _correctVerseRef);

    if (!correct) {
      _consecutiveCorrect = 0;
      final template =
          _wrongAnswerTemplates[Random().nextInt(_wrongAnswerTemplates.length)];
      wrongMsg = template.replaceFirst('%s', formattedAnswer);
    } else {
      _consecutiveCorrect++;
      if (_consecutiveCorrect == 10) {
        correctMsg =
            _milestone10Messages[Random().nextInt(_milestone10Messages.length)];
      } else if (_consecutiveCorrect == 5) {
        correctMsg =
            _milestone5Messages[Random().nextInt(_milestone5Messages.length)];
      } else if (_consecutiveCorrect == 3) {
        correctMsg =
            _milestone3Messages[Random().nextInt(_milestone3Messages.length)];
      } else {
        correctMsg = _correctAnswerMessages[
            Random().nextInt(_correctAnswerMessages.length)];
      }
      correctMsg = '$correctMsg It was $formattedAnswer.';
    }

    setState(() {
      _selectedChapter = chapter.number;
      _showAnswer = true;
      _totalAnswers++;
      if (correct) _correctAnswers++;
    });
    _showAnswerDialog(
      message:
          correct ? (correctMsg ?? 'Correct!') : (wrongMsg ?? 'Not quite.'),
      title: correct ? 'Correct' : 'Not quite',
      tint: correct ? Colors.green : AppColors.wrong,
      icon: correct ? Icons.check_circle : Icons.cancel_outlined,
    );
    if (correct && _consecutiveCorrect >= 3) {
      _confettiController.play();
    }
  }

  Future<void> _showAnswerDialog({
    required String message,
    required String title,
    required Color tint,
    required IconData icon,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(icon, color: tint, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Quiz',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
        ),
        body: const Center(child: SizedBox.shrink()),
      );
    }

    if (_error != null || _chapters.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Quiz',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error?.toString() ?? 'No chapters available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _loadQuiz,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quiz',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: LayoutBuilder(
                builder: (context, viewport) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 10,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$_correctAnswers/$_totalAnswers',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: _totalAnswers == 0
                                          ? AppColors.primary
                                              .withValues(alpha: 0.55)
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBeige,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _sectionVerseTexts
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final i = entry.key;
                                      final text = entry.value;
                                      final ref = i < _sectionRefs.length
                                          ? _sectionRefs[i]
                                          : null;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (ref != null) ...[
                                            Text(
                                              'Verse $ref',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontFamily: 'Lora',
                                                    color: AppColors.primary,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                          BcvVerseText(
                                            text: text,
                                            style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontFamily:
                                                          'Crimson Text',
                                                      fontSize: 19,
                                                      height: 1.45,
                                                      color: const Color(
                                                          0xFF2C2416),
                                                    ) ??
                                                const TextStyle(
                                                  fontFamily: 'Crimson Text',
                                                  fontSize: 19,
                                                  height: 1.45,
                                                  color: AppColors.textDark,
                                                ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'To which chapter does this belong?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showChapterLabels = !_showChapterLabels;
                                    });
                                  },
                                  icon: Icon(
                                    _showChapterLabels
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _showChapterLabels
                                        ? 'Hide names'
                                        : 'Show names',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 10,
                        child: LayoutBuilder(
                          builder: (context, pad) {
                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const ClampingScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                mainAxisExtent: _showChapterLabels ? 84 : 62,
                              ),
                              itemCount: 12,
                              itemBuilder: (context, index) {
                                if (index < 9) {
                                  final number = index + 1;
                                  return _buildChapterPadKey(
                                    context: context,
                                    chapter: _chapters
                                        .firstWhere((c) => c.number == number),
                                    isSelected: _selectedChapter == number,
                                    isCorrect: _showAnswer &&
                                        _correctChapterNumber == number,
                                    isWrong: _showAnswer &&
                                        _selectedChapter == number &&
                                        _correctChapterNumber != number,
                                    showLabel: _showChapterLabels,
                                  );
                                }
                                if (index == 9) {
                                  return _buildActionPadKey(
                                    context: context,
                                    label: 'Reveal',
                                    icon: Icons.visibility_outlined,
                                    onTap: _showAnswer ? null : _revealAnswer,
                                    filled: false,
                                  );
                                }
                                if (index == 10) {
                                  return _buildChapterPadKey(
                                    context: context,
                                    chapter: _chapters
                                        .firstWhere((c) => c.number == 10),
                                    isSelected: _selectedChapter == 10,
                                    isCorrect: _showAnswer &&
                                        _correctChapterNumber == 10,
                                    isWrong: _showAnswer &&
                                        _selectedChapter == 10 &&
                                        _correctChapterNumber != 10,
                                    showLabel: _showChapterLabels,
                                  );
                                }
                                return _buildActionPadKey(
                                  context: context,
                                  label: _showAnswer ? 'Next' : 'Skip',
                                  icon: _showAnswer
                                      ? Icons.arrow_forward
                                      : Icons.skip_next,
                                  onTap:
                                      _showAnswer ? _nextQuestion : _loadQuiz,
                                  filled: true,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              maxBlastForce: 40,
              minBlastForce: 15,
              emissionFrequency: 0.05,
              gravity: 0.15,
              createParticlePath: _createStarPath,
              minimumSize: const Size(12, 12),
              maximumSize: const Size(20, 20),
              colors: const [
                Color(0xFFFFD700), // Gold
                Colors.amber,
                Colors.amberAccent,
              ],
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizSectionData {
  const _QuizSectionData({
    required this.refs,
    required this.verseTexts,
    required this.chapterNumber,
  });

  final List<String> refs;
  final List<String> verseTexts;
  final int chapterNumber;

  String get verseRef => refs.first;
}
