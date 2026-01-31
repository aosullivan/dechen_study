import 'package:flutter/material.dart';
import '../../services/bcv_verse_service.dart';
import 'bcv_read_screen.dart';

/// Full-screen display of a random verse from bcv-root, with "Another verse" and back.
class DailyVerseScreen extends StatefulWidget {
  const DailyVerseScreen({super.key});

  @override
  State<DailyVerseScreen> createState() => _DailyVerseScreenState();
}

class _DailyVerseScreenState extends State<DailyVerseScreen> {
  final _verseService = BcvVerseService.instance;
  String _verse = '';
  String? _caption;
  int? _currentVerseIndex;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _verseService.getRandomVerseWithCaption();
      if (mounted) {
        setState(() {
          _verse = result.verse;
          _caption = result.caption;
          _currentVerseIndex = result.verseIndex;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2416)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily verse',
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
        child: CircularProgressIndicator(color: Color(0xFF8B7355)),
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
                onPressed: _loadVerse,
                child: const Text('Try again'),
              ),
            ],
          ),
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
              color: const Color(0xFFF8F7F3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8E4DC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_caption != null) ...[
                  Text(
                    _caption!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Lora',
                          color: const Color(0xFF8B7355),
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  _verse,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Crimson Text',
                        fontSize: 20,
                        height: 1.8,
                        color: const Color(0xFF2C2416),
                      ) ??
                      const TextStyle(
                        fontFamily: 'Crimson Text',
                        fontSize: 20,
                        height: 1.8,
                        color: Color(0xFF2C2416),
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
                  onPressed: _loading ? null : _loadVerse,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Another verse'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B7355),
                    side: const BorderSide(color: Color(0xFF8B7355)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentVerseIndex == null ? null : _openFullText,
                  icon: const Icon(Icons.book, size: 20),
                  label: const Text('Full text'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B7355),
                    side: const BorderSide(color: Color(0xFF8B7355)),
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
    if (_currentVerseIndex == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BcvReadScreen(scrollToVerseIndex: _currentVerseIndex),
      ),
    );
  }
}
