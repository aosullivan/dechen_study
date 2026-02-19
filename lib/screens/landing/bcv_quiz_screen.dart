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
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _consecutiveCorrect = 0;
  Object? _error;
  String? _wrongAnswerMessage;
  String? _correctAnswerMessage;
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
      _wrongAnswerMessage = null;
      _correctAnswerMessage = null;
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
    setState(() {
      _showAnswer = true;
      _selectedChapter = null;
      _wrongAnswerMessage = 'Answer: $formattedAnswer.';
      _correctAnswerMessage = null;
    });
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
      _wrongAnswerMessage = wrongMsg;
      _correctAnswerMessage = correctMsg;
    });
    if (correct && _consecutiveCorrect >= 3) {
      _confettiController.play();
    }
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

    final isCorrectSelection = _selectedChapter == _correctChapterNumber;
    final isRevealOnly = _showAnswer && _selectedChapter == null;

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
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_correctAnswers/$_totalAnswers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _totalAnswers == 0
                            ? AppColors.primary.withValues(alpha: 0.55)
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBeige,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showAnswer
                          ? (_selectedChapter == _correctChapterNumber
                              ? Colors.green
                              : AppColors.wrong)
                          : AppColors.borderLight,
                      width: _showAnswer ? 2 : 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _sectionVerseTexts.asMap().entries.map(
                        (entry) {
                          final i = entry.key;
                          final text = entry.value;
                          final ref =
                              i < _sectionRefs.length ? _sectionRefs[i] : null;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  i == _sectionVerseTexts.length - 1 ? 0 : 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                BcvVerseText(
                                  text: text,
                                  style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontFamily: 'Crimson Text',
                                            fontSize: 20,
                                            height: 1.5,
                                            color: const Color(0xFF2C2416),
                                          ) ??
                                      const TextStyle(
                                        fontFamily: 'Crimson Text',
                                        fontSize: 20,
                                        height: 1.5,
                                        color: AppColors.textDark,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'To which chapter does this belong?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 110,
                ),
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  final displayTitle = _displayChapterTitle(chapter);
                  final isSelected = _selectedChapter == chapter.number;
                  final isCorrect =
                      _showAnswer && chapter.number == _correctChapterNumber;
                  final isWrong = _showAnswer && isSelected && !isCorrect;

                  return Material(
                    color: Colors.transparent,
                    child: Semantics(
                      label: 'Chapter ${chapter.number}: $displayTitle',
                      button: true,
                      child: InkWell(
                        onTap:
                            _showAnswer ? null : () => _selectChapter(chapter),
                        borderRadius: BorderRadius.circular(12),
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final compact = box.maxWidth < 210;
                            final numberSize = compact ? 26.0 : 30.0;
                            final titleSize = compact ? 17.0 : 19.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green.withValues(alpha: 0.16)
                                    : (isWrong
                                        ? AppColors.wrong
                                            .withValues(alpha: 0.12)
                                        : (isSelected
                                            ? AppColors.primary
                                                .withValues(alpha: 0.12)
                                            : Colors.white)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCorrect
                                      ? Colors.green
                                      : (isWrong
                                          ? AppColors.wrong
                                          : AppColors.border),
                                  width: isCorrect || isWrong ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${chapter.number}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontSize: numberSize,
                                            fontWeight: FontWeight.w700,
                                            height: 1.0,
                                            color: isCorrect
                                                ? Colors.green.shade800
                                                : (isWrong
                                                    ? AppColors.wrong
                                                    : AppColors.textDark),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    displayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: titleSize,
                                          height: 1.15,
                                          fontWeight: FontWeight.w600,
                                          color: isCorrect
                                              ? Colors.green.shade800
                                              : (isWrong
                                                  ? AppColors.wrong
                                                  : AppColors.textDark),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_showAnswer) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isCorrectSelection
                            ? Colors.green
                            : (isRevealOnly
                                ? AppColors.primary
                                : AppColors.wrong))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isCorrectSelection
                              ? Colors.green
                              : (isRevealOnly
                                  ? AppColors.primary
                                  : AppColors.wrong))
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrectSelection
                            ? Icons.check_circle
                            : (isRevealOnly
                                ? Icons.info_outline
                                : Icons.cancel_outlined),
                        size: 26,
                        color: isCorrectSelection
                            ? Colors.green
                            : (isRevealOnly
                                ? AppColors.primary
                                : AppColors.wrong),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isCorrectSelection
                              ? (_correctAnswerMessage ?? 'Correct!')
                              : _wrongAnswerMessage ?? 'Not quite.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isCorrectSelection
                                        ? Colors.green.shade800
                                        : (isRevealOnly
                                            ? AppColors.primary
                                            : AppColors.darkBrown),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showAnswer ? null : _revealAnswer,
                      icon: const Icon(Icons.visibility_outlined),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: _showAnswer
                              ? AppColors.border
                              : AppColors.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text('Reveal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAnswer ? _nextQuestion : _loadQuiz,
                      icon: Icon(
                          _showAnswer ? Icons.arrow_forward : Icons.skip_next),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: Text(_showAnswer ? 'Next' : 'Skip'),
                    ),
                  ),
                ],
              ),
            ],
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
