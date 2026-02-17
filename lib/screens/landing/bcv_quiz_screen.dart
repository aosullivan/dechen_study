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
  late ConfettiController _confettiController;

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quiz',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (_totalAnswers > 0)
                        Text(
                          '$_correctAnswers / $_totalAnswers',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Section text – compact box, larger readable text
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showAnswer
                              ? (_selectedChapter == _correctChapterNumber
                                  ? Colors.green
                                  : AppColors.wrong)
                              : AppColors.border,
                          width: _showAnswer ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: BcvVerseText(
                          text: _sectionText,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Crimson Text',
                                fontSize: 18,
                                height: 1.65,
                              ) ??
                              const TextStyle(
                                fontFamily: 'Crimson Text',
                                fontSize: 18,
                                height: 1.65,
                              ),
                        ),
                      ),
                    ),
                ),
                const SizedBox(height: 10),

                // Question
                Text(
                  'To which chapter does this belong?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 8),

                // Chapter options: 2 neat rows of 5 (number + title per cell)
                LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 5;
                    const spacing = 8.0;
                    const rowHeight = 58.0;
                    final cellWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                    final rowCount = (_chapters.length / crossAxisCount).ceil();
                    final gridHeight = rowCount * rowHeight + (rowCount - 1) * spacing;
                    const maxGridHeight = 124.0;
                    return SizedBox(
                      height: gridHeight > maxGridHeight ? maxGridHeight : gridHeight,
                      child: GridView.builder(
                        physics: gridHeight <= maxGridHeight
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: cellWidth / rowHeight,
                        ),
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          final isSelected = _selectedChapter == chapter.number;
                          final isCorrect =
                              _showAnswer && chapter.number == _correctChapterNumber;
                          final isWrong = _showAnswer && isSelected && !isCorrect;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showAnswer
                                  ? null
                                  : () {
                                      final correct = chapter.number == _correctChapterNumber;
                                      String? wrongMsg;
                                      String? correctMsg;

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
                                        } else if (_consecutiveCorrect == 5) {
                                          correctMsg = _milestone5Messages[
                                              Random().nextInt(_milestone5Messages.length)];
                                        } else if (_consecutiveCorrect == 3) {
                                          correctMsg = _milestone3Messages[
                                              Random().nextInt(_milestone3Messages.length)];
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
                                      });
                                      if (correct && _consecutiveCorrect >= 3) {
                                        _confettiController.play();
                                      }
                                    },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                margin: const EdgeInsets.all(0),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : (isWrong
                                          ? AppColors.wrong.withValues(alpha: 0.15)
                                          : (isSelected
                                              ? AppColors.primary.withValues(alpha: 0.15)
                                              : Colors.white)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCorrect
                                        ? Colors.green
                                        : (isWrong ? AppColors.wrong : AppColors.border),
                                    width: isCorrect || isWrong ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${chapter.number}',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isCorrect
                                                ? Colors.green.shade800
                                                : (isWrong ? AppColors.wrong : AppColors.textDark),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      chapter.title,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: isCorrect
                                                ? Colors.green.shade800
                                                : (isWrong ? AppColors.wrong : AppColors.textDark),
                                            height: 1.2,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                // Answer feedback (always visible when answered – no scroll needed)
                if (_showAnswer) ...[
                  const SizedBox(height: 10),
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
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedChapter == _correctChapterNumber
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          size: 26,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ],
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
