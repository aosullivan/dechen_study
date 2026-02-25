import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../utils/widget_lifecycle_observer.dart';
import '../../services/verse_service.dart';
import '../../services/commentary_service.dart';
import '../../services/section_clue_service.dart';
import '../../services/usage_metrics_service.dart';
import 'bcv/bcv_verse_text.dart';

/// Guess the Chapter: pick which chapter a random section belongs to.
class GuessChapterScreen extends StatefulWidget {
  const GuessChapterScreen({
    super.key,
    required this.textId,
    required this.title,
  });

  final String textId;
  final String title;

  @override
  State<GuessChapterScreen> createState() => _GuessChapterScreenState();
}

class _GuessChapterScreenState extends State<GuessChapterScreen>
    with WidgetLifecycleObserver, WidgetsBindingObserver {
  final _verseService = VerseService.instance;
  final _commentaryService = CommentaryService.instance;
  final _clueService = SectionClueService.instance;
  final _usageMetrics = UsageMetricsService.instance;
  DateTime? _screenDwellStartedAt;

  bool _isLoading = true;
  List<String> _sectionVerseTexts = [];
  int _correctChapterNumber = 0;
  String? _correctVerseRef;
  List<Chapter> _chapters = [];
  int? _selectedChapter;
  bool _showAnswer = false;
  bool _showChapterLabels = false;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _consecutiveCorrect = 0;
  Object? _error;
  String? _clueText;
  bool _showClue = false;

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
    _screenDwellStartedAt = DateTime.now().toUtc();
    _loadQuiz();
  }

  @override
  void dispose() {
    _trackSurfaceDwell(nowUtc: DateTime.now().toUtc(), resetStart: true);
    unawaited(_usageMetrics.flush(all: true));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _trackSurfaceDwell(nowUtc: DateTime.now().toUtc(), resetStart: true);
      unawaited(_usageMetrics.flush(all: true));
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _screenDwellStartedAt ??= DateTime.now().toUtc();
    }
  }

  void _trackSurfaceDwell({
    required DateTime nowUtc,
    required bool resetStart,
  }) {
    final startedAt = _screenDwellStartedAt;
    if (startedAt == null) return;
    final durationMs = nowUtc.difference(startedAt).inMilliseconds;
    if (durationMs >= _usageMetrics.minDwellMs) {
      unawaited(_usageMetrics.trackSurfaceDwell(
        textId: widget.textId,
        mode: 'guess_chapter',
        durationMs: durationMs,
        chapterNumber: _correctChapterNumber > 0 ? _correctChapterNumber : null,
        verseRef: _correctVerseRef,
        properties: {
          'total_answers': _totalAnswers,
          'correct_answers': _correctAnswers,
        },
      ));
    }
    if (resetStart) _screenDwellStartedAt = null;
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _sectionVerseTexts = [];
      _correctChapterNumber = 0;
      _selectedChapter = null;
      _showAnswer = false;
      _clueText = null;
    });
    try {
      final chapters = await _verseService.getChapters(widget.textId);
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
      final clue = await _clueService.getClueForRef(widget.textId, section.verseRef);
      if (mounted) {
        setState(() {
          _sectionVerseTexts = section.verseTexts;
          _correctChapterNumber = section.chapterNumber;
          _correctVerseRef = section.verseRef;
          _chapters = chapters;
          _clueText = clue;
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
      final section = await _commentaryService.getRandomSection(widget.textId);
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
      final idx = _verseService.getIndexForRef(widget.textId, ref);
      if (idx == null) continue;
      final text = _verseService.getVerseAt(widget.textId, idx);
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
      final baseRef = ref.replaceAll(VerseService.segmentSuffixPattern, '');
      if (!VerseService.baseVerseRefPattern.hasMatch(baseRef)) continue;
      if (!seen.add(baseRef)) continue;
      normalized.add(baseRef);
    }
    return normalized;
  }

  String _formattedAnswer(Chapter chapter, String? verseRef) {
    final verse = verseRef?.trim();
    if (verse == null || verse.isEmpty) {
      return 'Chapter ${chapter.number}: ${chapter.title}';
    }
    return 'Chapter ${chapter.number}: ${chapter.title} - verse $verse';
  }

  String _displayChapterTitle(Chapter chapter) {
    return _shortChapterTitles[chapter.number] ?? chapter.title;
  }

  Widget _buildChapterPadKey({
    required BuildContext context,
    required Chapter chapter,
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
      child: Semantics(
        button: true,
        label: 'Chapter ${chapter.number}: $label',
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
                          : AppColors.cardBeige)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect
                    ? Colors.green
                    : (isWrong ? AppColors.wrong : AppColors.border),
                width: isCorrect || isWrong ? 1.8 : 1,
              ),
            ),
            child: showLabel
                ? Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${chapter.number}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    height: 1.0,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    height: 1.16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '${chapter.number}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                height: 1.0,
                              ),
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
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.cardBeige,
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
                          fontSize: 12,
                          color: filled ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _nextQuestion() {
    unawaited(_usageMetrics.trackEvent(
      eventName: 'quiz_next_question_tapped',
      textId: widget.textId,
      mode: 'guess_chapter',
      chapterNumber: _correctChapterNumber > 0 ? _correctChapterNumber : null,
      verseRef: _correctVerseRef,
      properties: {'from_state': _showAnswer ? 'next' : 'skip'},
    ));
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
    unawaited(_usageMetrics.trackEvent(
      eventName: 'quiz_answer_revealed',
      textId: widget.textId,
      mode: 'guess_chapter',
      chapterNumber: _correctChapterNumber,
      verseRef: _correctVerseRef,
      properties: {'reason': 'skipped_or_revealed'},
    ));
    _showAnswerDialog(
      message: message,
      title: 'Answer',
      tint: AppColors.primary,
      icon: Icons.info_outline,
    );
  }

  void _selectChapter(Chapter chapter) {
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
    unawaited(_usageMetrics.trackQuizAttempt(
      textId: widget.textId,
      mode: 'guess_chapter',
      correct: correct,
      chapterNumber: _correctChapterNumber,
      verseRef: _correctVerseRef,
    ));
    _showAnswerDialog(
      message:
          correct ? (correctMsg ?? 'Correct!') : (wrongMsg ?? 'Not quite.'),
      title: correct ? 'Correct' : 'Not quite',
      tint: correct ? Colors.green : AppColors.wrong,
      icon: correct ? Icons.check_circle : Icons.cancel_outlined,
    );
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
        backgroundColor: AppColors.landingBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Guess the Chapter',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
        ),
        body: const Center(child: SizedBox.shrink()),
      );
    }

    if (_error != null || _chapters.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.landingBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Guess the Chapter',
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
      backgroundColor: AppColors.landingBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Guess the Chapter',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_correctAnswers/$_totalAnswers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _totalAnswers == 0
                            ? AppColors.primary.withValues(alpha: 0.55)
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBeige,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _sectionVerseTexts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      BcvVerseText(
                        text: _sectionVerseTexts[i],
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
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'To which chapter does this belong?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textDark,
                    ),
              ),
              if (_showClue && _clueText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textDark.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.textDark.withValues(alpha: 0.14),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Clue: $_clueText',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textDark.withValues(alpha: 0.85),
                            fontSize: 17,
                            height: 1.34,
                          ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (_showChapterLabels) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 5 * 78 + 4 * 6,
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          mainAxisExtent: 78,
                        ),
                        itemCount: 10,
                        itemBuilder: (context, index) {
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
                            showLabel: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 42,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionPadKey(
                              context: context,
                              label: 'Reveal',
                              icon: Icons.visibility_outlined,
                              onTap: _showAnswer ? null : _revealAnswer,
                              filled: false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionPadKey(
                              context: context,
                              label: _showAnswer ? 'Next' : 'Skip',
                              icon: _showAnswer
                                  ? Icons.arrow_forward
                                  : Icons.skip_next,
                              onTap: _nextQuestion,
                              filled: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  height: 4 * 54 + 3 * 6,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      mainAxisExtent: 54,
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
                          showLabel: false,
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
                          chapter:
                              _chapters.firstWhere((c) => c.number == 10),
                          isSelected: _selectedChapter == 10,
                          isCorrect:
                              _showAnswer && _correctChapterNumber == 10,
                          isWrong: _showAnswer &&
                              _selectedChapter == 10 &&
                              _correctChapterNumber != 10,
                          showLabel: false,
                        );
                      }
                      return _buildActionPadKey(
                        context: context,
                        label: _showAnswer ? 'Next' : 'Skip',
                        icon: _showAnswer
                            ? Icons.arrow_forward
                            : Icons.skip_next,
                        onTap: _nextQuestion,
                        filled: true,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_clueText != null && !_showAnswer)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showClue = !_showClue);
                      },
                      icon: Icon(
                        _showClue
                            ? Icons.lightbulb
                            : Icons.lightbulb_outline,
                        size: 18,
                      ),
                      label: Text(
                        _showClue ? 'Hide clue' : 'Show clue',
                        style: Theme.of(context).textTheme.bodyMedium,
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
                      size: 18,
                    ),
                    label: Text(
                      _showChapterLabels
                          ? 'Hide chapter names'
                          : 'Show chapter names',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
