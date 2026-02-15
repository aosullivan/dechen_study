import 'package:flutter/material.dart';

import '../../models/study_models.dart';
import '../../services/study_service.dart';
import '../../utils/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _studyService = StudyService.instance;
  bool _isLoading = true;
  Section? _currentSection;
  List<Chapter> _chapters = [];
  int? _selectedChapter;
  bool _showAnswer = false;
  int _correctAnswers = 0;
  int _totalAnswers = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);

    final chapters = await _studyService.getChapters();
    final section = await _studyService.getRandomSection();

    setState(() {
      _chapters = chapters;
      _currentSection = section;
      _isLoading = false;
      _selectedChapter = null;
      _showAnswer = false;
    });
  }

  void _nextQuestion() {
    _loadQuiz();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_currentSection == null || _chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No study text available yet. Please upload a text first.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quiz',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_totalAnswers > 0)
                  Text(
                    '$_correctAnswers / $_totalAnswers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section text (no chapter/verse shown - same style as daily section)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _showAnswer
                    ? (_selectedChapter == _currentSection!.chapterNumber
                        ? Colors.green
                        : AppColors.wrong)
                    : AppColors.border,
                width: _showAnswer ? 2 : 1,
              ),
            ),
            child: Text(
              _currentSection!.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Text(
            'To which chapter does this belong?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Chapter options - tap to answer immediately
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _chapters.map((chapter) {
              final isSelected = _selectedChapter == chapter.number;
              final isCorrect = _showAnswer &&
                  chapter.number == _currentSection!.chapterNumber;
              final isWrong = _showAnswer && isSelected && !isCorrect;

              return ChoiceChip(
                label: Text('Chapter ${chapter.number}'),
                selected: isSelected,
                onSelected: _showAnswer
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() {
                            _selectedChapter = chapter.number;
                            _showAnswer = true;
                            _totalAnswers++;
                            if (chapter.number == _currentSection!.chapterNumber) {
                              _correctAnswers++;
                            }
                          });
                        }
                      },
                selectedColor: isCorrect
                    ? Colors.green.withValues(alpha: 0.3)
                    : (isWrong
                        ? AppColors.wrong.withValues(alpha: 0.3)
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

          // Answer feedback - satisfying green check or red x
          if (_showAnswer) ...[
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (_selectedChapter == _currentSection!.chapterNumber
                          ? Colors.green
                          : AppColors.wrong)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_selectedChapter == _currentSection!.chapterNumber
                              ? Colors.green
                              : AppColors.wrong)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _selectedChapter == _currentSection!.chapterNumber
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 64,
                  color: _selectedChapter == _currentSection!.chapterNumber
                      ? Colors.green
                      : AppColors.wrong,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
