import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../utils/app_theme.dart';
import '../../services/commentary_service.dart';
import 'bcv/bcv_verse_text.dart';
import 'bcv_read_screen.dart';

/// Full-screen display of a random section (one or more verses) from the commentary mapping,
/// with "Another section" and "Full text" link that jumps to Read with the section highlighted.
class DailyVerseScreen extends StatefulWidget {
  const DailyVerseScreen({super.key});

  @override
  State<DailyVerseScreen> createState() => _DailyVerseScreenState();
}

class _DailyVerseScreenState extends State<DailyVerseScreen> {
  final _verseService = BcvVerseService.instance;
  final _commentaryService = CommentaryService.instance;

  /// Current section: refs and their verse texts (in order).
  List<String> _sectionRefs = [];
  List<String> _sectionVerseTexts = [];
  /// Verse indices in the flat list for deep link and highlight.
  Set<int> _sectionVerseIndices = {};
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadSection();
  }

  Future<void> _loadSection() async {
    setState(() {
      _loading = true;
      _error = null;
      _sectionRefs = [];
      _sectionVerseTexts = [];
      _sectionVerseIndices = {};
    });
    try {
      final section = await _commentaryService.getRandomSection();
      if (section == null || section.refsInBlock.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'No sections available';
          });
        }
        return;
      }
      await _verseService.getChapters();
      final refs = section.refsInBlock;
      final texts = <String>[];
      final indices = <int>{};
      for (final ref in refs) {
        final idx = _verseService.getIndexForRef(ref);
        if (idx != null) {
          indices.add(idx);
          final text = _verseService.getVerseAt(idx);
          texts.add(text ?? '');
        }
      }
      if (mounted) {
        setState(() {
          _sectionRefs = refs;
          _sectionVerseTexts = texts;
          _sectionVerseIndices = indices;
          _loading = false;
        });
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

  String get _sectionCaption {
    if (_sectionRefs.isEmpty) return '';
    if (_sectionRefs.length == 1) {
      final ref = _sectionRefs.single;
      final parts = ref.split('.');
      if (parts.length == 2) return 'Chapter ${parts[0]}, Verse ${parts[1]}';
      return 'Verse $ref';
    }
    final first = _sectionRefs.first;
    final last = _sectionRefs.last;
    final cFirst = first.split('.').firstOrNull ?? '';
    final cLast = last.split('.').firstOrNull ?? '';
    if (cFirst != cLast) return 'Verses ${_sectionRefs.join(', ')}';
    final verseNums = _sectionRefs.map((r) => int.tryParse(r.split('.').lastOrNull ?? '') ?? 0).toList();
    final contiguous = verseNums.length > 1 &&
        (verseNums.last - verseNums.first + 1) == verseNums.length;
    if (contiguous) {
      return 'Chapter $cFirst, Verses ${verseNums.first}–${verseNums.last}';
    }
    return 'Chapter $cFirst, Verses ${_sectionRefs.map((r) => r.split('.').last).join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily section',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
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
                onPressed: _loadSection,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_sectionRefs.isEmpty) {
      return Center(
        child: Text(
          'No section loaded.',
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
                  _sectionCaption,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 16),
                ..._sectionVerseTexts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final text = entry.value;
                  final ref = i < _sectionRefs.length ? _sectionRefs[i] : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ref != null && _sectionRefs.length > 1) ...[
                          Text(
                            'Verse $ref',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Lora',
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        BcvVerseText(
                          text: text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loadSection,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Another section'),
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
                  onPressed: _sectionVerseIndices.isEmpty ? null : _openFullText,
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
    if (_sectionVerseIndices.isEmpty) return;
    final sorted = _sectionVerseIndices.toList()..sort();
    final firstIndex = sorted.first;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BcvReadScreen(
          scrollToVerseIndex: firstIndex,
          highlightSectionIndices: _sectionVerseIndices,
        ),
      ),
    );
  }
}
