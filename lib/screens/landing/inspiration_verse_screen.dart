import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../services/inspiration_service.dart';
import '../../utils/app_theme.dart';
import 'bcv/bcv_verse_text.dart';
import 'bcv_read_screen.dart';

/// Shows one random verse for the chosen feeling. "Another" gives a new random verse.
class InspirationVerseScreen extends StatefulWidget {
  const InspirationVerseScreen({
    super.key,
    required this.feelingId,
    required this.feelingLabel,
  });

  final String feelingId;
  final String feelingLabel;

  @override
  State<InspirationVerseScreen> createState() => _InspirationVerseScreenState();
}

class _InspirationVerseScreenState extends State<InspirationVerseScreen> {
  final _service = InspirationService.instance;
  final _verseService = BcvVerseService.instance;

  InspirationRandomVerse? _verse;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadRandomVerse();
  }

  Future<void> _loadRandomVerse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final verse = await _service.getRandomVerseForFeeling(widget.feelingId);
      if (mounted) {
        setState(() {
          _verse = verse;
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

  String get _verseCaption {
    if (_verse == null) return '';
    final ref = _verse!.verseRef;
    final parts = ref.split('.');
    if (parts.length >= 2) {
      return 'Chapter ${parts[0]}, Verse ${parts[1]}';
    }
    return 'Verse $ref';
  }

  int? get _verseIndex {
    if (_verse == null) return null;
    return _verseService.getIndexForRefWithFallback(_verse!.verseRef);
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
          widget.feelingLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: SizedBox.shrink());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load verse',
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
                onPressed: _loadRandomVerse,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_verse == null || _verse!.verseText.isEmpty) {
      return Center(
        child: Text(
          'No verses available for this feeling.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.cardBeige,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _verse!.sectionTitle,
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
                BcvVerseText(
                  text: _verse!.verseText,
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
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadRandomVerse,
                  icon: const Icon(Icons.shuffle, size: 20),
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
                  onPressed: _verseIndex != null ? _openFullText : null,
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
    final idx = _verseIndex;
    if (idx == null) return;
    final ref = _verse?.verseRef;
    final initialSegmentRef =
        ref != null && BcvVerseService.segmentSuffixPattern.hasMatch(ref)
            ? ref
            : null;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BcvReadScreen(
          scrollToVerseIndex: idx,
          highlightSectionIndices: {idx},
          initialSegmentRef: initialSegmentRef,
        ),
      ),
    );
  }
}
