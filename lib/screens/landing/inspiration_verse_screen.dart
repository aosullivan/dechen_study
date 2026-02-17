import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../services/inspiration_service.dart';
import '../../utils/app_theme.dart';
import 'bcv/bcv_verse_text.dart';
import 'bcv_read_screen.dart';

/// Displays sections for a chosen emotion sequentially, like Daily but filtered.
class InspirationVerseScreen extends StatefulWidget {
  const InspirationVerseScreen({super.key, required this.emotion});

  final String emotion;

  @override
  State<InspirationVerseScreen> createState() => _InspirationVerseScreenState();
}

class _InspirationVerseScreenState extends State<InspirationVerseScreen> {
  final _verseService = BcvVerseService.instance;
  final _inspirationService = InspirationService.instance;

  List<InspirationSection> _sections = [];
  int _currentIndex = 0;

  List<String> _verseRefs = [];
  List<String> _verseTexts = [];
  Set<int> _verseIndices = {};
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sections =
          await _inspirationService.getSectionsForEmotion(widget.emotion);
      await _verseService.getChapters();
      if (mounted) {
        setState(() {
          _sections = sections;
          _currentIndex = 0;
        });
        _loadCurrentSection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  void _loadCurrentSection() {
    if (_sections.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No sections found for this feeling';
      });
      return;
    }
    final section = _sections[_currentIndex];
    final texts = <String>[];
    final indices = <int>{};
    for (final ref in section.verseRefs) {
      final idx = _verseService.getIndexForRefWithFallback(ref);
      if (idx != null) {
        indices.add(idx);
        texts.add(_verseService.getVerseAt(idx) ?? '');
      }
    }
    setState(() {
      _verseRefs = section.verseRefs;
      _verseTexts = texts;
      _verseIndices = indices;
      _loading = false;
    });
  }

  void _nextSection() {
    if (_sections.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _sections.length;
    });
    _loadCurrentSection();
  }

  String get _sectionTitle {
    if (_sections.isEmpty) return '';
    return _sections[_currentIndex].title;
  }

  String get _verseCaption {
    if (_verseRefs.isEmpty) return '';
    if (_verseRefs.length == 1) {
      final ref = _verseRefs.single;
      final parts = ref.split('.');
      if (parts.length == 2) return 'Chapter ${parts[0]}, Verse ${parts[1]}';
      return 'Verse $ref';
    }
    final first = _verseRefs.first;
    final last = _verseRefs.last;
    final cFirst = first.split('.').firstOrNull ?? '';
    final cLast = last.split('.').firstOrNull ?? '';
    if (cFirst != cLast) return 'Verses ${_verseRefs.join(', ')}';
    final verseNums = _verseRefs
        .map((r) => int.tryParse(r.split('.').lastOrNull ?? '') ?? 0)
        .toList();
    final contiguous = verseNums.length > 1 &&
        (verseNums.last - verseNums.first + 1) == verseNums.length;
    if (contiguous) {
      return 'Chapter $cFirst, Verses ${verseNums.first}\u2013${verseNums.last}';
    }
    return 'Chapter $cFirst, Verses ${_verseRefs.map((r) => r.split('.').last).join(', ')}';
  }

  String get _positionLabel {
    if (_sections.isEmpty) return '';
    return '${_currentIndex + 1} of ${_sections.length}';
  }

  @override
  Widget build(BuildContext context) {
    final label =
        InspirationService.emotionLabels[widget.emotion] ?? widget.emotion;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load section',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _loadSections,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_verseRefs.isEmpty) {
      return Center(
        child: Text(
          'No verses available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBeige,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'Crimson Text',
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _verseCaption,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 16),
                ..._verseTexts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final text = entry.value;
                  final ref = i < _verseRefs.length ? _verseRefs[i] : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ref != null) ...[
                          Text(
                            'Verse $ref',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _positionLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'Lora',
                    color: AppColors.mutedBrown,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sections.length <= 1 ? null : _nextSection,
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: const Text('Another'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _verseIndices.isEmpty ? null : _openFullText,
                  icon: const Icon(Icons.book, size: 20),
                  label: const Text('Full text'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openFullText() {
    if (_verseIndices.isEmpty) return;
    final sorted = _verseIndices.toList()..sort();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BcvReadScreen(
          scrollToVerseIndex: sorted.first,
          highlightSectionIndices: _verseIndices,
        ),
      ),
    );
  }
}
