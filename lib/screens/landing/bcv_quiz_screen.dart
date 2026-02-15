import 'dart:math';
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import 'package:lottie/lottie.dart';
import '../../services/bcv_verse_service.dart';
import '../../services/commentary_service.dart';

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
  String _sectionText = '';
  int _correctChapterNumber = 0;
  List<BcvChapter> _chapters = [];
  int? _selectedChapter;
  bool _showAnswer = false;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _consecutiveCorrect = 0;
  Object? _error;
  String? _wrongAnswerMessage;
  String? _correctAnswerMessage;
  bool _showLottieCelebration = false;

  static final _verseRefPattern = RegExp(r'\[\d+\.\d+\]');
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

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _sectionText = '';
      _correctChapterNumber = 0;
      _selectedChapter = null;
      _showAnswer = false;
      _wrongAnswerMessage = null;
      _correctAnswerMessage = null;
    });
    try {
      final section = await _commentaryService.getRandomSection();
      if (section == null || section.refsInBlock.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'No sections available';
          });
        }
        return;
      }
      await _verseService.getChapters();
      final refs = section.refsInBlock;
      final texts = <String>[];
      for (final ref in refs) {
        final idx = _verseService.getIndexForRef(ref);
        if (idx != null) {
          final text = _verseService.getVerseAt(idx) ?? '';
          texts.add(_stripVerseRef(text));
        }
      }
      final chapterNum = int.tryParse(refs.first.split('.').first) ?? 1;
      final chapters = await _verseService.getChapters();
      if (mounted) {
        setState(() {
          _sectionText = texts.join('\n\n');
          _correctChapterNumber = chapterNum;
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

  /// Strip [c.v] markers so we don't reveal the chapter.
  String _stripVerseRef(String text) {
    return text.replaceAll(_verseRefPattern, '').trim();
  }

  void _nextQuestion() {
    _loadQuiz();
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
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
          SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quiz',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_totalAnswers > 0)
                    Text(
                      '$_correctAnswers / $_totalAnswers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Section text (no chapter/verse shown)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _showAnswer
                      ? (_selectedChapter == _correctChapterNumber
                          ? Colors.green
                          : AppColors.wrong)
                      : AppColors.border,
                  width: _showAnswer ? 2 : 1,
                ),
              ),
              child: Text(
                _sectionText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Crimson Text',
                      fontSize: 16,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            // Question
            Text(
              'To which chapter does this belong?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),

            // Chapter options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chapters.map((chapter) {
                final isSelected = _selectedChapter == chapter.number;
                final isCorrect =
                    _showAnswer && chapter.number == _correctChapterNumber;
                final isWrong = _showAnswer && isSelected && !isCorrect;

                return ChoiceChip(
                  label: Text('Chapter ${chapter.number}: ${chapter.title}'),
                  selected: isSelected,
                  onSelected: _showAnswer
                      ? null
                      : (selected) {
                          if (selected) {
                            final correct = chapter.number == _correctChapterNumber;
                            String? wrongMsg;
                            String? correctMsg;
                            bool showConfetti = false;

                            if (!correct) {
                              _consecutiveCorrect = 0;
                              final chapterStr = _chapters
                                  .where((c) => c.number == _correctChapterNumber)
                                  .map((c) => 'Chapter ${c.number}: ${c.title}')
                                  .firstOrNull ?? 'Chapter $_correctChapterNumber';
                              final template = _wrongAnswerTemplates[
                                  Random().nextInt(_wrongAnswerTemplates.length)];
                              wrongMsg = template.replaceFirst('%s', chapterStr);
                            } else {
                              _consecutiveCorrect++;
                              if (_consecutiveCorrect == 10) {
                                correctMsg = _milestone10Messages[
                                    Random().nextInt(_milestone10Messages.length)];
                                showConfetti = true;
                              } else if (_consecutiveCorrect == 5) {
                                correctMsg = _milestone5Messages[
                                    Random().nextInt(_milestone5Messages.length)];
                                showConfetti = true;
                              } else if (_consecutiveCorrect == 3) {
                                correctMsg = _milestone3Messages[
                                    Random().nextInt(_milestone3Messages.length)];
                                showConfetti = true;
                              } else {
                                correctMsg = _correctAnswerMessages[
                                    Random().nextInt(_correctAnswerMessages.length)];
                              }
                            }

                            setState(() {
                              _selectedChapter = chapter.number;
                              _showAnswer = true;
                              _totalAnswers++;
                              if (correct) _correctAnswers++;
                              _wrongAnswerMessage = wrongMsg;
                              _correctAnswerMessage = correctMsg;
                              _showLottieCelebration = showConfetti;
                            });
                            if (showConfetti) {
                              Future.delayed(const Duration(seconds: 3), () {
                                if (mounted) {
                                  setState(() => _showLottieCelebration = false);
                                }
                              });
                            }
                          }
                        },
                  selectedColor: isCorrect
                      ? Colors.green.withValues(alpha: 0.3)
                      : (isWrong
                          ? AppColors.wrong.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.3)),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isCorrect
                        ? Colors.green
                        : (isWrong ? AppColors.wrong : AppColors.border),
                  ),
                );
              }).toList(),
            ),

            // Answer feedback
            if (_showAnswer) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (_selectedChapter == _correctChapterNumber
                          ? Colors.green
                          : AppColors.wrong)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_selectedChapter == _correctChapterNumber
                            ? Colors.green
                            : AppColors.wrong)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedChapter == _correctChapterNumber
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      size: 28,
                      color: _selectedChapter == _correctChapterNumber
                          ? Colors.green
                          : AppColors.wrong,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedChapter == _correctChapterNumber
                            ? (_correctAnswerMessage ?? 'Correct!')
                            : _wrongAnswerMessage ?? 'Not quite.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedChapter == _correctChapterNumber
                                  ? Colors.green.shade800
                                  : AppColors.darkBrown,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ],
        ),
      ),
          if (_showLottieCelebration)
            Align(
              alignment: Alignment.center,
              child: IgnorePointer(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Lottie.network(
                    'https://assets3.lottiefiles.com/packages/lf20_UJNc2t.json',
                    fit: BoxFit.contain,
                    repeat: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
