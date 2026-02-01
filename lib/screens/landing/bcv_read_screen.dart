import 'package:flutter/material.dart';
import '../../services/bcv_verse_service.dart';
import '../../services/commentary_service.dart';

/// Read screen for Bodhicaryavatara: sidebar with chapter list, main area with full text.
/// Optional [scrollToVerseIndex] scrolls to the exact verse after first frame.
/// Optional [highlightSectionIndices] highlights all verses in that section (e.g. from Daily).
class BcvReadScreen extends StatefulWidget {
  const BcvReadScreen({
    super.key,
    this.scrollToVerseIndex,
    this.highlightSectionIndices,
    this.title = 'Bodhicaryavatara',
  });

  final int? scrollToVerseIndex;
  /// When provided (e.g. from Daily "Full text"), these verses are highlighted as one section.
  final Set<int>? highlightSectionIndices;
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
  /// Verses to highlight (set when arriving from Daily or when user taps a verse); cleared on reload.
  Set<int> _highlightVerseIndices = {};
  /// Commentary for the currently selected verse group (loaded on tap); null if none or not loaded.
  CommentaryEntry? _commentaryEntryForSelected;
  final _commentaryService = CommentaryService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.scrollToVerseIndex != null || (widget.highlightSectionIndices?.isNotEmpty ?? false)) {
      _scrollToVerseKey = GlobalKey();
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _highlightVerseIndices = {};
      _commentaryEntryForSelected = null;
    });
    try {
      final chapters = await _verseService.getChapters();
      final verses = _verseService.getVerses();
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _verses = verses;
          _loading = false;
          if (widget.highlightSectionIndices != null && widget.highlightSectionIndices!.isNotEmpty) {
            _highlightVerseIndices = Set<int>.from(widget.highlightSectionIndices!);
          } else if (widget.scrollToVerseIndex != null) {
            _highlightVerseIndices = {widget.scrollToVerseIndex!};
          }
          for (final c in chapters) {
            _chapterKeys[c.number] = GlobalKey();
          }
        });
        if (widget.scrollToVerseIndex != null && _scrollToVerseKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerseWidget());
        }
        if (widget.highlightSectionIndices != null && _highlightVerseIndices.isNotEmpty) {
          _loadCommentaryForHighlightedSection();
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

  /// Load commentary for the currently highlighted section (e.g. from Daily) so the Commentary button shows.
  Future<void> _loadCommentaryForHighlightedSection() async {
    if (_highlightVerseIndices.isEmpty) return;
    final firstIndex = _highlightVerseIndices.reduce((a, b) => a < b ? a : b);
    final ref = _verseService.getVerseRef(firstIndex);
    if (ref == null) return;
    final entry = await _commentaryService.getCommentaryForRef(ref);
    if (!mounted) return;
    setState(() {
      _commentaryEntryForSelected = entry;
    });
  }

  /// Consecutive verse indices from _highlightVerseIndices, for one continuous highlight per run.
  List<List<int>> _getHighlightRuns() {
    if (_highlightVerseIndices.isEmpty) return [];
    final sorted = _highlightVerseIndices.toList()..sort();
    final runs = <List<int>>[];
    var current = [sorted.first];
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == current.last + 1) {
        current.add(sorted[i]);
      } else {
        runs.add(current);
        current = [sorted[i]];
      }
    }
    runs.add(current);
    return runs;
  }

  Future<void> _onVerseTap(int globalIndex) async {
    // If clicking a verse that's already highlighted, clear selection
    if (_highlightVerseIndices.contains(globalIndex)) {
      setState(() {
        _highlightVerseIndices = {};
        _commentaryEntryForSelected = null;
      });
      return;
    }
    
    // Get the verse ref and load commentary
    final ref = _verseService.getVerseRef(globalIndex);
    if (ref == null) return;
    
    final entry = await _commentaryService.getCommentaryForRef(ref);
    if (!mounted) return;
    
    // If this verse has no commentary, just highlight it alone
    if (entry == null) {
      setState(() {
        _highlightVerseIndices = {globalIndex};
        _commentaryEntryForSelected = null;
      });
      return;
    }
    
    // Find all verse indices in the commentary block
    final verseIndicesInBlock = <int>{};
    for (final verseRef in entry.refsInBlock) {
      final idx = _verseService.getIndexForRef(verseRef);
      if (idx != null) {
        verseIndicesInBlock.add(idx);
      }
    }
    
    setState(() {
      _highlightVerseIndices = verseIndicesInBlock;
      _commentaryEntryForSelected = entry;
    });
  }

  /// Strip verse ref lines and verse text from commentary body so we show verses once at top.
  String _commentaryOnly(CommentaryEntry entry) {
    String body = entry.commentaryText;
    for (final ref in entry.refsInBlock) {
      // Remove line that is just the ref (e.g. "2.60")
      body = body.replaceAll(RegExp('^${RegExp.escape(ref)}\\s*\$', multiLine: true), '');
      final verseText = _verseService.getIndexForRef(ref) != null
          ? _verseService.getVerseAt(_verseService.getIndexForRef(ref)!)
          : null;
      if (verseText != null && verseText.isNotEmpty) {
        // Remove the verse text block (may be multiple lines)
        body = body.replaceAll(verseText, '');
      }
    }
    // Collapse multiple newlines and trim
    return body.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  void _showCommentaryBottomSheet() {
    final entry = _commentaryEntryForSelected;
    if (entry == null) return;
    final verseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Crimson Text',
          fontSize: 18,
          height: 1.8,
          color: const Color(0xFF2C2416),
        );
    final headingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'Lora',
          color: const Color(0xFF8B7355),
        );
    final commentaryOnly = _commentaryOnly(entry);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              if (entry.refsInBlock.length == 1) ...[
                Text(
                  'Verse ${entry.refsInBlock.single}',
                  style: headingStyle,
                ),
                const SizedBox(height: 12),
                Text(
                  _verseService.getIndexForRef(entry.refsInBlock.single) != null
                      ? (_verseService.getVerseAt(
                          _verseService.getIndexForRef(entry.refsInBlock.single)!,
                        ) ?? '')
                      : '',
                  style: verseStyle,
                ),
              ] else ...[
                Text(
                  'Verses ${entry.refsInBlock.join(", ")}',
                  style: headingStyle,
                ),
                const SizedBox(height: 12),
                ...entry.refsInBlock.map((ref) {
                  final idx = _verseService.getIndexForRef(ref);
                  final text = idx != null ? _verseService.getVerseAt(idx) : null;
                  if (text == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verse $ref',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Lora',
                                color: const Color(0xFF8B7355),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(text, style: verseStyle),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
              Text('Commentary', style: headingStyle),
              const SizedBox(height: 12),
              Text(
                commentaryOnly,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Crimson Text',
                      fontSize: 18,
                      height: 1.8,
                      color: const Color(0xFF2C2416),
                    ),
              ),
            ],
          ),
        ),
      ),
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
              ...() {
                final runs = _getHighlightRuns();
                final usedInRun = <int>{};
                final verseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Crimson Text',
                      fontSize: 18,
                      height: 1.8,
                      color: const Color(0xFF2C2416),
                    );
                final highlightDecoration = BoxDecoration(
                  color: const Color(0xFFEADCC4).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF8B7355).withValues(alpha: 0.4),
                    width: 1,
                  ),
                );

                Widget buildSingleVerse(int gIdx, String verseText) {
                  final isTargetVerse = widget.scrollToVerseIndex != null &&
                      widget.scrollToVerseIndex == gIdx &&
                      _scrollToVerseKey != null;
                  Widget w = Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(verseText, style: verseStyle),
                  );
                  if (_highlightVerseIndices.contains(gIdx)) {
                    w = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: highlightDecoration,
                      child: w,
                    );
                  }
                  w = GestureDetector(
                    onTap: () => _onVerseTap(gIdx),
                    behavior: HitTestBehavior.opaque,
                    child: w,
                  );
                  if (isTargetVerse) {
                    w = KeyedSubtree(key: _scrollToVerseKey, child: w);
                  }
                  return w;
                }

                final children = <Widget>[];
                List<int>? runContaining(int idx) {
                  for (final r in runs) {
                    if (r.contains(idx)) return r;
                  }
                  return null;
                }

                for (final entry in verseTexts.asMap().entries) {
                  final localIndex = entry.key;
                  final verse = entry.value;
                  final globalIndex = ch.startVerseIndex + localIndex;
                  if (usedInRun.contains(globalIndex)) continue;
                  final run = runContaining(globalIndex);
                  if (run != null && run.first == globalIndex) {
                    for (final idx in run) {
                      usedInRun.add(idx);
                    }
                    final runVerseWidgets = run.map((idx) {
                      final text = idx < _verses.length ? _verses[idx] : '';
                      final isTargetVerse = widget.scrollToVerseIndex != null &&
                          widget.scrollToVerseIndex == idx &&
                          _scrollToVerseKey != null;
                      Widget w = Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(text, style: verseStyle),
                      );
                      w = GestureDetector(
                        onTap: () => _onVerseTap(idx),
                        behavior: HitTestBehavior.opaque,
                        child: w,
                      );
                      if (isTargetVerse) {
                        w = KeyedSubtree(key: _scrollToVerseKey, child: w);
                      }
                      return w;
                    }).toList();
                    final highlightBlock = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: highlightDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: runVerseWidgets,
                      ),
                    );
                    final hasCommentary = _commentaryEntryForSelected != null;
                    children.add(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          highlightBlock,
                          if (hasCommentary) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _showCommentaryBottomSheet,
                              icon: const Icon(Icons.menu_book, size: 18, color: Color(0xFF8B7355)),
                              label: const Text(
                                'Commentary',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  color: Color(0xFF8B7355),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  } else {
                    children.add(buildSingleVerse(globalIndex, verse));
                  }
                }
                return children;
              }(),
              const SizedBox(height: 32),
            ],
          );
        }).toList(),
      ),
    );
  }
}
