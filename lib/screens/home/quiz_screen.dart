import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/study_models.dart';
import '../../services/study_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _studyService = StudyService();
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

  void _checkAnswer() {
    if (_selectedChapter == null || _currentSection == null) return;

    setState(() {
      _showAnswer = true;
      _totalAnswers++;
      if (_selectedChapter == _currentSection!.chapterNumber) {
        _correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    _loadQuiz();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B7355)),
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
              color: const Color(0xFF8B7355).withOpacity(0.1),
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
                          color: const Color(0xFF8B7355),
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Instructions
          Text(
            'Which chapter is this section from?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          // Section text
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _showAnswer
                    ? (_selectedChapter == _currentSection!.chapterNumber
                        ? Colors.green
                        : Colors.red)
                    : const Color(0xFFD4C4B0),
                width: _showAnswer ? 2 : 1,
              ),
            ),
            child: Text(
              _currentSection!.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),

          // Chapter options
          Text(
            'Select a chapter:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _chapters.map((chapter) {
              final isSelected = _selectedChapter == chapter.number;
              final isCorrect = _showAnswer && chapter.number == _currentSection!.chapterNumber;
              final isWrong = _showAnswer && isSelected && !isCorrect;

              return ChoiceChip(
                label: Text('Chapter ${chapter.number}'),
                selected: isSelected,
                onSelected: _showAnswer
                    ? null
                    : (selected) {
                        setState(() {
                          _selectedChapter = selected ? chapter.number : null;
                        });
                      },
                selectedColor: isCorrect
                    ? Colors.green.withOpacity(0.3)
                    : (isWrong
                        ? Colors.red.withOpacity(0.3)
                        : const Color(0xFF8B7355).withOpacity(0.3)),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isCorrect
                      ? Colors.green
                      : (isWrong
                          ? Colors.red
                          : const Color(0xFFD4C4B0)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedChapter == null
                  ? null
                  : (_showAnswer ? _nextQuestion : _checkAnswer),
              child: Text(_showAnswer ? 'Next Question' : 'Check Answer'),
            ),
          ),

          // Answer feedback
          if (_showAnswer) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_selectedChapter == _currentSection!.chapterNumber
                        ? Colors.green
                        : Colors.red)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (_selectedChapter == _currentSection!.chapterNumber
                          ? Colors.green
                          : Colors.red)
                      .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedChapter == _currentSection!.chapterNumber
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: _selectedChapter == _currentSection!.chapterNumber
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedChapter == _currentSection!.chapterNumber
                          ? 'Correct! This is from Chapter ${_currentSection!.chapterNumber}.'
                          : 'Not quite. This section is from Chapter ${_currentSection!.chapterNumber}.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
