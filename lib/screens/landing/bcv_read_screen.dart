import 'package:flutter/material.dart';
import '../../services/bcv_verse_service.dart';

/// Read screen for Bodhicaryavatara: sidebar with chapter list, main area with full text.
/// Optional [scrollToVerseIndex] scrolls to the exact verse after first frame.
class BcvReadScreen extends StatefulWidget {
  const BcvReadScreen({
    super.key,
    this.scrollToVerseIndex,
    this.title = 'Bodhicaryavatara',
  });

  final int? scrollToVerseIndex;
  final String title;

  @override
  State<BcvReadScreen> createState() => _BcvReadScreenState();
}

class _BcvReadScreenState extends State<BcvReadScreen> {
  final _verseService = BcvVerseService.instance;
  List<BcvChapter> _chapters = [];
  List<String> _verses = [];
  bool _loading = true;
  Object? _error;
  final Map<int, GlobalKey> _chapterKeys = {};
  GlobalKey? _scrollToVerseKey;

  @override
  void initState() {
    super.initState();
    if (widget.scrollToVerseIndex != null) {
      _scrollToVerseKey = GlobalKey();
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chapters = await _verseService.getChapters();
      final verses = _verseService.getVerses();
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _verses = verses;
          _loading = false;
          for (final c in chapters) {
            _chapterKeys[c.number] = GlobalKey();
          }
        });
        if (widget.scrollToVerseIndex != null && _scrollToVerseKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerseWidget());
        }
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

  void _scrollToChapter(int chapterNumber) {
    final key = _chapterKeys[chapterNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!, alignment: 0.0, duration: const Duration(milliseconds: 300));
    }
  }

  void _scrollToVerseWidget() {
    if (_scrollToVerseKey?.currentContext == null) return;
    Scrollable.ensureVisible(
      _scrollToVerseKey!.currentContext!,
      alignment: 0.2,
      duration: const Duration(milliseconds: 300),
    );
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
          widget.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B7355)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load text', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_error.toString(), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_chapters.isEmpty) {
      return Center(
        child: Text(
          'No chapters available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSidebar(),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        border: Border(
          right: BorderSide(color: const Color(0xFFD4C4B0).withValues(alpha: 0.5)),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        itemCount: _chapters.length,
        itemBuilder: (context, index) {
          final ch = _chapters[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _scrollToChapter(ch.number),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(
                    'Chapter ${ch.number}: ${ch.title}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Lora',
                          color: const Color(0xFF2C2416),
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _chapters.map((ch) {
          final key = _chapterKeys[ch.number];
          final verseTexts = ch.startVerseIndex < _verses.length
              ? _verses.sublist(ch.startVerseIndex, ch.endVerseIndex.clamp(0, _verses.length))
              : <String>[];
          return Column(
            key: key,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chapter ${ch.number}: ${ch.title}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontFamily: 'Crimson Text',
                      color: const Color(0xFF2C2416),
                    ),
              ),
              const SizedBox(height: 24),
              ...verseTexts.asMap().entries.map((entry) {
                final localIndex = entry.key;
                final verse = entry.value;
                final globalIndex = ch.startVerseIndex + localIndex;
                final isTargetVerse = widget.scrollToVerseIndex != null &&
                    widget.scrollToVerseIndex == globalIndex &&
                    _scrollToVerseKey != null;
                final verseWidget = Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    verse,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Crimson Text',
                          fontSize: 18,
                          height: 1.8,
                          color: const Color(0xFF2C2416),
                        ),
                  ),
                );
                if (isTargetVerse) {
                  return KeyedSubtree(
                    key: _scrollToVerseKey,
                    child: verseWidget,
                  );
                }
                return verseWidget;
              }),
              const SizedBox(height: 32),
            ],
          );
        }).toList(),
      ),
    );
  }
}
