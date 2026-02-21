import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../services/bcv_file_quiz_service.dart';
import '../../services/bcv_verse_service.dart';
import '../../utils/app_theme.dart';
import 'bcv/bcv_verse_text.dart';

class BcvFileQuizScreen extends StatefulWidget {
  const BcvFileQuizScreen({super.key});

  @override
  State<BcvFileQuizScreen> createState() => _BcvFileQuizScreenState();
}

class _BcvFileQuizScreenState extends State<BcvFileQuizScreen> {
  final _quizService = BcvFileQuizService.instance;
  final _verseService = BcvVerseService.instance;
  final _random = Random();

  late final ConfettiController _confettiController;

  bool _isLoading = true;
  Object? _error;
  BcvFileQuizDifficulty _difficulty = BcvFileQuizDifficulty.beginner;
  List<BcvFileQuizQuestion> _questions = const [];
  List<int> _order = const [];
  int _orderCursor = 0;
  int? _currentQuestionIndex;
  String? _selectedOptionKey;
  bool _showAnswer = false;

  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _consecutiveCorrect = 0;

  static final _correctAnswerMessages = [
    'Well done! That is correct.',
    'Brilliant! Spot on.',
    'Exactly right.',
    'Nice one! Correct.',
    'You got it.',
    'Perfect! Well done.',
    'Spot on! Good job.',
    'Correct! Nice work.',
  ];

  static final _milestone3Messages = [
    'Three in a row! You are on a roll.',
    'Three consecutive! Brilliant streak.',
    'Hat-trick! Well done.',
  ];

  static final _milestone5Messages = [
    'Five in a row! Fantastic.',
    'Five straight! You are unstoppable.',
    'Brilliant run! Five correct.',
  ];

  static final _milestone10Messages = [
    'Ten in a row! Incredible.',
    'Double digits! Outstanding.',
    'Ten straight! You are flying.',
  ];

  static final _wrongAnswerTemplates = [
    'Not quite. The answer was: %s.',
    'Close. It was actually: %s.',
    'Good try. The answer was: %s.',
    'Not this time. It was: %s.',
    'Almost there. It was: %s.',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadDifficulty(_difficulty, resetScore: true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadDifficulty(
    BcvFileQuizDifficulty difficulty, {
    required bool resetScore,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _difficulty = difficulty;
      if (resetScore) {
        _correctAnswers = 0;
        _totalAnswers = 0;
        _consecutiveCorrect = 0;
      }
    });

    try {
      final loaded = await _quizService.loadQuestions(difficulty);
      await _verseService.getChapters();
      final order = _quizService.buildShuffledOrder(loaded.length, _random);

      if (!mounted) return;
      setState(() {
        _questions = loaded;
        _order = order;
        _orderCursor = 0;
        _currentQuestionIndex = null;
        _selectedOptionKey = null;
        _showAnswer = false;
        _isLoading = false;
      });
      _nextQuestion();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  BcvFileQuizQuestion? get _currentQuestion {
    final index = _currentQuestionIndex;
    if (index == null || index < 0 || index >= _questions.length) return null;
    return _questions[index];
  }

  String get _difficultyLabel {
    return _difficulty == BcvFileQuizDifficulty.beginner
        ? 'Beginner'
        : 'Advanced';
  }

  void _nextQuestion() {
    if (_questions.isEmpty) return;
    if (_orderCursor >= _order.length) {
      _order = _quizService.buildShuffledOrder(_questions.length, _random);
      _orderCursor = 0;
    }

    final index = _order[_orderCursor++];
    setState(() {
      _currentQuestionIndex = index;
      _selectedOptionKey = null;
      _showAnswer = false;
    });
  }

  List<_ResolvedVerse> _resolveVerses(List<String> refs) {
    if (refs.isEmpty) {
      return const [
        _ResolvedVerse(
          ref: '',
          text:
              'No verse reference was found for this question in the source file.',
        ),
      ];
    }

    final results = <_ResolvedVerse>[];
    for (final ref in refs) {
      final index = _verseService.getIndexForRefWithFallback(ref);
      if (index == null) {
        results.add(
          _ResolvedVerse(
              ref: ref, text: 'Verse text not found for this reference.'),
        );
        continue;
      }
      final text = _verseService.getVerseAt(index);
      if (text == null || text.trim().isEmpty) {
        results.add(
          _ResolvedVerse(
              ref: ref, text: 'Verse text not found for this reference.'),
        );
      } else {
        results.add(_ResolvedVerse(ref: ref, text: text));
      }
    }
    return results;
  }

  void _revealAnswer() {
    final q = _currentQuestion;
    if (q == null || _showAnswer) return;
    final resolvedVerses = _resolveVerses(q.verseRefs);

    setState(() {
      _showAnswer = true;
      _selectedOptionKey = null;
      _consecutiveCorrect = 0;
    });

    _showResultDialog(
      title: 'Answer',
      message: 'Answer: ${q.correctAnswerText}',
      tint: AppColors.primary,
      icon: Icons.info_outline,
      verses: resolvedVerses,
    );
  }

  void _selectAnswer(String key) {
    final q = _currentQuestion;
    if (q == null || _showAnswer) return;

    final correct = key == q.answerKey;
    final correctText = q.correctAnswerText;
    final resolvedVerses = _resolveVerses(q.verseRefs);
    String message;

    if (correct) {
      _consecutiveCorrect++;
      if (_consecutiveCorrect == 10) {
        message =
            _milestone10Messages[_random.nextInt(_milestone10Messages.length)];
      } else if (_consecutiveCorrect == 5) {
        message =
            _milestone5Messages[_random.nextInt(_milestone5Messages.length)];
      } else if (_consecutiveCorrect == 3) {
        message =
            _milestone3Messages[_random.nextInt(_milestone3Messages.length)];
      } else {
        message = _correctAnswerMessages[
            _random.nextInt(_correctAnswerMessages.length)];
      }
      message = '$message Answer: $correctText';
    } else {
      _consecutiveCorrect = 0;
      final template =
          _wrongAnswerTemplates[_random.nextInt(_wrongAnswerTemplates.length)];
      message = template.replaceFirst('%s', correctText);
    }

    setState(() {
      _selectedOptionKey = key;
      _showAnswer = true;
      _totalAnswers++;
      if (correct) _correctAnswers++;
    });

    _showResultDialog(
      title: correct ? 'Correct' : 'Not quite',
      message: message,
      tint: correct ? Colors.green : AppColors.wrong,
      icon: correct ? Icons.check_circle : Icons.cancel_outlined,
      verses: resolvedVerses,
    );

    if (correct && _consecutiveCorrect >= 3) {
      _confettiController.play();
    }
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required Color tint,
    required IconData icon,
    required List<_ResolvedVerse> verses,
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
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 12),
                _buildVerseDialogPanel(verses),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton({
    required BcvFileQuizDifficulty value,
    required String label,
    required VoidCallback onTap,
  }) {
    final selected = _difficulty == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _isLoading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String key,
    String text,
    BcvFileQuizQuestion question,
  ) {
    final isSelected = _selectedOptionKey == key;
    final isCorrect = key == question.answerKey;
    final showCorrect = _showAnswer && isCorrect;
    final showWrong = _showAnswer && isSelected && !isCorrect;

    final borderColor = showCorrect
        ? Colors.green
        : (showWrong ? AppColors.wrong : AppColors.border);
    final fillColor = showCorrect
        ? Colors.green.withValues(alpha: 0.10)
        : (showWrong
            ? AppColors.wrong.withValues(alpha: 0.10)
            : (isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _showAnswer ? null : () => _selectAnswer(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: borderColor, width: showCorrect || showWrong ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
                child: Text(
                  key.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseDialogPanel(List<_ResolvedVerse> verses) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Underlying Verse${verses.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < verses.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.borderLight),
                  ),
                if (verses[i].ref.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      verses[i].ref,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                BcvVerseText(
                  text: verses[i].text,
                  style: const TextStyle(
                    fontFamily: 'Crimson Text',
                    fontSize: 18,
                    height: 1.42,
                    color: Color(0xFF2C2416),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Quiz', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
        ),
        body: const Center(child: SizedBox.shrink()),
      );
    }

    if (_error != null || question == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Quiz', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error?.toString() ?? 'No quiz questions available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      _loadDifficulty(_difficulty, resetScore: false),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final orderedKeys = question.options.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Quiz', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: LayoutBuilder(
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            _difficultyLabel,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          const Spacer(),
                          Text(
                            '$_correctAnswers/$_totalAnswers',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _totalAnswers == 0
                                          ? AppColors.primary
                                              .withValues(alpha: 0.55)
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildDifficultyButton(
                            value: BcvFileQuizDifficulty.beginner,
                            label: 'Beginner',
                            onTap: () => _loadDifficulty(
                              BcvFileQuizDifficulty.beginner,
                              resetScore: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDifficultyButton(
                            value: BcvFileQuizDifficulty.advanced,
                            label: 'Advanced',
                            onTap: () => _loadDifficulty(
                              BcvFileQuizDifficulty.advanced,
                              resetScore: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${question.number}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.prompt,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontSize: 20,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final key in orderedKeys) ...[
                                _buildOptionButton(
                                  context,
                                  key,
                                  question.options[key] ?? '',
                                  question,
                                ),
                                const SizedBox(height: 6),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showAnswer ? null : _revealAnswer,
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Reveal'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showAnswer
                                  ? _nextQuestion
                                  : () => _nextQuestion(),
                              icon: Icon(
                                _showAnswer
                                    ? Icons.arrow_forward
                                    : Icons.skip_next,
                              ),
                              label: Text(_showAnswer ? 'Next' : 'Skip'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
              numberOfParticles: 36,
              maxBlastForce: 34,
              minBlastForce: 12,
              emissionFrequency: 0.06,
              gravity: 0.18,
              minimumSize: const Size(10, 10),
              maximumSize: const Size(16, 16),
              colors: const [
                Color(0xFFFFD700),
                Colors.amber,
                Colors.amberAccent
              ],
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedVerse {
  const _ResolvedVerse({required this.ref, required this.text});

  final String ref;
  final String text;
}
