import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/verse_service.dart';
import '../../services/usage_metrics_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/surface_dwell_tracker.dart';
import '../../utils/verse_ref_formatter.dart';
import '../../utils/widget_lifecycle_observer.dart';
import '../../services/commentary_service.dart';
import '../../services/verse_hierarchy_service.dart';
import 'bcv/bcv_verse_text.dart';
import 'read_screen.dart';

/// Full-screen display of a random section (one or more verses) from the commentary mapping,
/// with "Another section" and "Full text" link that jumps to Read with the section highlighted.
class DailyVerseScreen extends StatefulWidget {
  const DailyVerseScreen({
    super.key,
    required this.textId,
    required this.title,
    this.verseService,
    this.commentaryService,
    this.hierarchyService,
    this.randomSectionLoader,
    this.verseIndexForRef,
    this.verseTextForIndex,
    this.minLinesForSection = 4,
    this.maxLinesForSection = 20,
    this.onResolvedRefsForTest,
    this.breadcrumbSummariesLoader,
  });

  final String textId;
  final String title;
  final VerseService? verseService;
  final CommentaryService? commentaryService;
  final VerseHierarchyService? hierarchyService;

  /// Test seam: override random-section loading to make widget tests deterministic.
  final Future<CommentaryEntry?> Function()? randomSectionLoader;

  /// Test seam: override verse index lookup by ref.
  final int? Function(String ref)? verseIndexForRef;

  /// Test seam: override verse text lookup by index.
  final String? Function(int index)? verseTextForIndex;

  /// Minimum total displayed logical lines for the daily block.
  /// If fewer, the block expands to parent section refs.
  final int minLinesForSection;

  /// Maximum total displayed logical lines for the daily block.
  /// Sections above this are skipped and another section is selected.
  final int maxLinesForSection;

  /// Test seam: captures resolved refs after min-line expansion logic.
  final void Function(List<String> refs)? onResolvedRefsForTest;

  /// Optional loader for authored breadcrumb summaries keyed by section path.
  final Future<Map<String, String>> Function(String textId)?
      breadcrumbSummariesLoader;

  @override
  State<DailyVerseScreen> createState() => _DailyVerseScreenState();
}

class _DailyVerseScreenState extends State<DailyVerseScreen>
    with
        WidgetLifecycleObserver,
        WidgetsBindingObserver,
        SurfaceDwellTracker<DailyVerseScreen> {
  final _usageMetrics = UsageMetricsService.instance;
  late final VerseService _verseService;
  late final CommentaryService _commentaryService;
  late final VerseHierarchyService _hierarchyService;

  /// Current section: refs and their verse texts (in order).
  List<String> _sectionRefs = [];
  List<String> _sectionVerseTexts = [];
  String _sectionTitle = '';
  String _sectionPath = '';
  String _sectionBreadcrumbSummary = '';
  Map<String, String>? _breadcrumbSummaries;
  bool _breadcrumbSummariesLoadAttempted = false;

  /// Verse indices in the flat list for deep link and highlight.
  Set<int> _sectionVerseIndices = {};
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    startSurfaceDwellTracking();
    _verseService = widget.verseService ?? VerseService.instance;
    _commentaryService = widget.commentaryService ?? CommentaryService.instance;
    _hierarchyService =
        widget.hierarchyService ?? VerseHierarchyService.instance;
    _loadSection();
  }

  @override
  void dispose() {
    flushSurfaceDwell(resetStart: true);
    flushSurfaceDwellQueue();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleSurfaceLifecycleState(state);
  }

  @override
  String get dwellTextId => widget.textId;

  @override
  String get dwellMode => 'daily';

  @override
  String? get dwellSectionPath => _sectionPath;

  @override
  String? get dwellSectionTitle => _sectionTitle;

  @override
  String? get dwellVerseRef =>
      _sectionRefs.isNotEmpty ? _sectionRefs.first : null;

  @override
  Map<String, dynamic>? get dwellProperties =>
      {'refs_count': _sectionRefs.length};

  String _segmentTextForRef(String ref, String fullText) {
    final lines = fullText.split('\n');
    final range = VerseService.lineRangeForSegmentRef(ref, lines.length);
    if (range == null) return fullText;
    return lines.sublist(range[0], range[1] + 1).join('\n');
  }

  String _baseRef(String ref) {
    final m = RegExp(r'^(\d+\.\d+)', caseSensitive: false).firstMatch(ref);
    return m?.group(1) ?? ref;
  }

  String _displayRef(String ref) =>
      formatBaseVerseRefForDisplay(widget.textId, _baseRef(ref));

  List<String> _hierarchyCandidatesForRef(String ref) {
    final out = <String>{};
    out.add(ref);
    final m =
        RegExp(r'^(\d+\.\d+)([a-z]+)?$', caseSensitive: false).firstMatch(ref);
    if (m != null) {
      final base = m.group(1)!;
      final suffix = (m.group(2) ?? '').toLowerCase();
      if (suffix.isNotEmpty) {
        if (suffix == 'a') out.add('${base}ab');
        if (suffix == 'bcd') out.add('${base}cd');
        if (suffix == 'ab') out.add('${base}a');
        if (suffix == 'cd') out.add('${base}bcd');
      }
      out.add(base);
    }
    return out.toList();
  }

  Future<String?> _leafSectionPathForRef(String ref) async {
    for (final candidate in _hierarchyCandidatesForRef(ref)) {
      final hierarchy = await _hierarchyService.getHierarchyForVerse(
          widget.textId, candidate);
      if (hierarchy.isEmpty) continue;
      final sec = hierarchy.last['section'] ?? hierarchy.last['path'] ?? '';
      if (sec.isNotEmpty) return sec;
    }
    return null;
  }

  String _parentPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0) return '';
    return path.substring(0, dot);
  }

  int _logicalLineCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.split('\n').length;
  }

  int _totalLogicalLines(List<String> texts) {
    var total = 0;
    for (final t in texts) {
      total += _logicalLineCount(t);
    }
    return total;
  }

  int _compareRefsForDisplay(
    String a,
    String b,
    int? Function(String ref) indexForRef,
  ) {
    final ai = indexForRef(a);
    final bi = indexForRef(b);
    if (ai != null && bi != null && ai != bi) return ai.compareTo(bi);
    if (ai != null && bi == null) return -1;
    if (ai == null && bi != null) return 1;

    final ar = VerseService.lineRangeForSegmentRef(a, 4);
    final br = VerseService.lineRangeForSegmentRef(b, 4);
    if (ar != null && br != null) {
      final cStart = ar[0].compareTo(br[0]);
      if (cStart != 0) return cStart;
      final cEnd = ar[1].compareTo(br[1]);
      if (cEnd != 0) return cEnd;
    } else if (ar != null && br == null) {
      return 1;
    } else if (ar == null && br != null) {
      return -1;
    }

    final bc = VerseHierarchyService.compareVerseRefs(_baseRef(a), _baseRef(b));
    if (bc != 0) return bc;
    return a.compareTo(b);
  }

  ({int chapter, int verse})? _chapterVerseFromRef(String ref) {
    final m = RegExp(r'^(\d+)\.(\d+)', caseSensitive: false).firstMatch(ref);
    if (m == null) return null;
    final chapter = int.tryParse(m.group(1)!);
    final verse = int.tryParse(m.group(2)!);
    if (chapter == null || verse == null) return null;
    return (chapter: chapter, verse: verse);
  }

  bool _isConsecutiveOrSameVerse(
    ({int chapter, int verse}) previous,
    ({int chapter, int verse}) next,
  ) {
    if (previous.chapter != next.chapter) return false;
    final delta = next.verse - previous.verse;
    return delta >= 0 && delta <= 1;
  }

  /// Returns the local consecutive run (same chapter, no verse gaps > 1)
  /// around [anchorRef] from a sorted ref list.
  List<String> _consecutiveRunAroundAnchor(
    List<String> sortedRefs, {
    required String anchorRef,
  }) {
    if (sortedRefs.isEmpty) return const [];
    final parsed = sortedRefs.map(_chapterVerseFromRef).toList();
    final anchorCv = _chapterVerseFromRef(anchorRef);
    if (anchorCv == null) return sortedRefs;

    var anchorIndex = parsed.indexWhere(
      (cv) =>
          cv != null &&
          cv.chapter == anchorCv.chapter &&
          cv.verse == anchorCv.verse,
    );
    if (anchorIndex < 0) {
      anchorIndex = parsed
          .indexWhere((cv) => cv != null && cv.chapter == anchorCv.chapter);
    }
    if (anchorIndex < 0) return sortedRefs;

    var start = anchorIndex;
    var end = anchorIndex;

    while (start > 0) {
      final prev = parsed[start - 1];
      final current = parsed[start];
      if (prev == null ||
          current == null ||
          !_isConsecutiveOrSameVerse(prev, current)) {
        break;
      }
      start--;
    }

    while (end < parsed.length - 1) {
      final current = parsed[end];
      final next = parsed[end + 1];
      if (current == null ||
          next == null ||
          !_isConsecutiveOrSameVerse(current, next)) {
        break;
      }
      end++;
    }

    return sortedRefs.sublist(start, end + 1);
  }

  ({List<String> refs, List<String> texts, Set<int> indices})
      _buildSectionContent(
    List<String> refs,
    int? Function(String ref) indexForRef,
    String? Function(int index) textForIndex,
  ) {
    final deduped = <({String ref, int? idx, bool merged})>[];
    final seenByKey = <String, int>{};
    for (final ref in refs) {
      final idx = indexForRef(ref);
      final key = 'r:${_baseRef(ref)}';
      final existing = seenByKey[key];
      if (existing == null) {
        seenByKey[key] = deduped.length;
        deduped.add((ref: ref, idx: idx, merged: false));
      } else {
        final item = deduped[existing];
        deduped[existing] = (ref: item.ref, idx: item.idx, merged: true);
      }
    }

    final outRefs = <String>[];
    final texts = <String>[];
    final indices = <int>{};
    for (final item in deduped) {
      outRefs.add(item.ref);
      final idx = item.idx;
      if (idx != null) {
        indices.add(idx);
        final fullText = textForIndex(idx) ?? '';
        texts.add(
          item.merged ? fullText : _segmentTextForRef(item.ref, fullText),
        );
      } else {
        texts.add('');
      }
    }
    return (refs: outRefs, texts: texts, indices: indices);
  }

  Future<String?> _deepestCommonLeafPath(List<String> refs) async {
    final paths = <List<String>>[];
    for (final ref in refs) {
      final leafPath = await _leafSectionPathForRef(ref);
      if (leafPath == null || leafPath.isEmpty) continue;
      paths.add(leafPath.split('.'));
    }
    if (paths.isEmpty) return null;
    var common = paths.first;
    for (var i = 1; i < paths.length; i++) {
      final next = paths[i];
      final limit = common.length < next.length ? common.length : next.length;
      var j = 0;
      while (j < limit && common[j] == next[j]) {
        j++;
      }
      common = common.sublist(0, j);
      if (common.isEmpty) break;
    }
    if (common.isEmpty) return null;
    return common.join('.');
  }

  Future<String> _sectionTitleForRefs(
    List<String> refs, {
    String? sectionPath,
  }) async {
    String titleFromPath(String path) {
      if (path.isEmpty) return '';
      final hierarchy =
          _hierarchyService.getHierarchyForSectionSync(widget.textId, path);
      if (hierarchy.isEmpty) return '';
      return (hierarchy.last['title'] ?? '').trim();
    }

    final path = sectionPath ?? await _deepestCommonLeafPath(refs);
    if (path != null && path.isNotEmpty) {
      final title = titleFromPath(path);
      if (title.isNotEmpty) return title;
    }

    for (final ref in refs) {
      final hierarchy =
          await _hierarchyService.getHierarchyForVerse(widget.textId, ref);
      if (hierarchy.isEmpty) continue;
      final title = (hierarchy.last['title'] ?? '').trim();
      if (title.isNotEmpty) return title;
    }
    return '';
  }

  Future<void> _ensureBreadcrumbSummariesLoaded() async {
    if (_breadcrumbSummariesLoadAttempted) return;
    _breadcrumbSummariesLoadAttempted = true;
    try {
      if (widget.breadcrumbSummariesLoader != null) {
        _breadcrumbSummaries =
            await widget.breadcrumbSummariesLoader!(widget.textId);
        return;
      }
      final raw = await rootBundle
          .loadString('texts/${widget.textId}/breadcrumb_summaries.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _breadcrumbSummaries = decoded.map<String, String>(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
      } else {
        _breadcrumbSummaries = const <String, String>{};
      }
    } catch (_) {
      _breadcrumbSummaries = const <String, String>{};
    }
  }

  String _lookupSummaryForPath(String path) {
    final summaries = _breadcrumbSummaries;
    if (summaries == null || summaries.isEmpty || path.isEmpty) return '';
    var cursor = path;
    while (cursor.isNotEmpty) {
      final summary = (summaries[cursor] ?? '').trim();
      if (summary.isNotEmpty) return summary;
      final dot = cursor.lastIndexOf('.');
      if (dot <= 0) break;
      cursor = cursor.substring(0, dot);
    }
    return '';
  }

  String _breadcrumbSummaryForPath(String path) {
    final authoredSummary = _lookupSummaryForPath(path);
    if (authoredSummary.isNotEmpty) return authoredSummary;

    if (path.isEmpty) return '';
    final hierarchy =
        _hierarchyService.getHierarchyForSectionSync(widget.textId, path);
    if (hierarchy.isEmpty) return '';
    final titles = hierarchy
        .map((item) => (item['title'] ?? '').trim())
        .where((title) => title.isNotEmpty)
        .toList();
    if (titles.isEmpty) return '';
    return titles.join(' > ');
  }

  Future<void> _refreshAuthoredBreadcrumbSummaryForPath(String path) async {
    await _ensureBreadcrumbSummariesLoaded();
    if (!mounted) return;
    final authored = _lookupSummaryForPath(path);
    if (authored.isEmpty || authored == _sectionBreadcrumbSummary) return;
    setState(() {
      _sectionBreadcrumbSummary = authored;
    });
  }

  Future<void> _loadSection() async {
    setState(() {
      _loading = true;
      _error = null;
      _sectionRefs = [];
      _sectionVerseTexts = [];
      _sectionTitle = '';
      _sectionPath = '';
      _sectionBreadcrumbSummary = '';
      _sectionVerseIndices = {};
    });
    try {
      final sectionLoader = widget.randomSectionLoader ??
          () => _commentaryService.getRandomSection(widget.textId);
      final indexForRef = widget.verseIndexForRef ??
          (ref) => _verseService.getIndexForRefWithFallback(widget.textId, ref);
      final textForIndex = widget.verseTextForIndex ??
          (index) => _verseService.getVerseAt(widget.textId, index);
      final usingCustomResolvers =
          widget.verseIndexForRef != null && widget.verseTextForIndex != null;
      if (!usingCustomResolvers) {
        await _verseService.getChapters(widget.textId);
      }

      const maxPickAttempts = 60;
      ({List<String> refs, List<String> texts, Set<int> indices})? picked;
      String? pickedSectionPath;
      for (var attempt = 0; attempt < maxPickAttempts; attempt++) {
        final section = await sectionLoader();
        if (section == null || section.refsInBlock.isEmpty) {
          continue;
        }

        var refs = List<String>.from(section.refsInBlock);
        refs.sort((a, b) => _compareRefsForDisplay(a, b, indexForRef));
        var content = _buildSectionContent(refs, indexForRef, textForIndex);
        var sectionPath = await _deepestCommonLeafPath(content.refs);
        final anchorRef =
            content.refs.isNotEmpty ? content.refs.first : refs.firstOrNull;

        if (widget.minLinesForSection > 0 &&
            _totalLogicalLines(content.texts) < widget.minLinesForSection) {
          final visitedParents = <String>{};
          while (sectionPath != null &&
              sectionPath.isNotEmpty &&
              _totalLogicalLines(content.texts) < widget.minLinesForSection) {
            final parent = _parentPath(sectionPath);
            if (parent.isEmpty || !visitedParents.add(parent)) break;
            final parentRefs = _hierarchyService
                .getVerseRefsForSectionSync(widget.textId, parent)
                .toList();
            if (parentRefs.isEmpty) break;
            parentRefs
                .sort((a, b) => _compareRefsForDisplay(a, b, indexForRef));
            final runRefs = anchorRef != null
                ? _consecutiveRunAroundAnchor(parentRefs, anchorRef: anchorRef)
                : parentRefs;
            content = _buildSectionContent(runRefs, indexForRef, textForIndex);
            sectionPath = await _deepestCommonLeafPath(content.refs) ?? parent;
          }
        }

        final lineCount = _totalLogicalLines(content.texts);
        if (widget.maxLinesForSection > 0 &&
            lineCount > widget.maxLinesForSection) {
          continue;
        }

        picked = content;
        pickedSectionPath = sectionPath;
        break;
      }

      if (picked == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = widget.maxLinesForSection > 0
                ? 'No sections available at or under ${widget.maxLinesForSection} lines'
                : 'No sections available';
          });
        }
        return;
      }
      final content = picked!;
      final sectionPath = pickedSectionPath;
      final sectionTitle =
          await _sectionTitleForRefs(content.refs, sectionPath: sectionPath);

      if (mounted) {
        widget.onResolvedRefsForTest?.call(content.refs);
        setState(() {
          _sectionRefs = content.refs;
          _sectionVerseTexts = content.texts;
          _sectionTitle = sectionTitle;
          _sectionPath = sectionPath ?? '';
          _sectionBreadcrumbSummary =
              _breadcrumbSummaryForPath(sectionPath ?? '');
          _sectionVerseIndices = content.indices;
          _loading = false;
        });
        unawaited(_refreshAuthoredBreadcrumbSummaryForPath(sectionPath ?? ''));
        unawaited(_usageMetrics.trackEvent(
          eventName: 'daily_section_loaded',
          textId: widget.textId,
          mode: 'daily',
          sectionPath: _sectionPath,
          sectionTitle: _sectionTitle,
          verseRef: _sectionRefs.isNotEmpty ? _sectionRefs.first : null,
          properties: {
            'refs_count': _sectionRefs.length,
            'line_count': _totalLogicalLines(_sectionVerseTexts),
          },
        ));
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily verses',
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
    final shownDisplayRefs = <String>{};
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
                ..._sectionVerseTexts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final text = entry.value;
                  final ref = i < _sectionRefs.length ? _sectionRefs[i] : null;
                  final displayRef = ref == null ? null : _displayRef(ref);
                  final shouldShowDisplayRef =
                      displayRef != null && displayRef.isNotEmpty
                          ? shownDisplayRefs.add(displayRef)
                          : false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (shouldShowDisplayRef) ...[
                          Text(
                            'Verse $displayRef',
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
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                  onPressed: _loading
                      ? null
                      : () {
                          unawaited(_usageMetrics.trackEvent(
                            eventName: 'daily_another_section_tapped',
                            textId: widget.textId,
                            mode: 'daily',
                            sectionPath: _sectionPath,
                            sectionTitle: _sectionTitle,
                            verseRef: _sectionRefs.isNotEmpty
                                ? _sectionRefs.first
                                : null,
                          ));
                          _loadSection();
                        },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('More Verses'),
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
                  onPressed:
                      _sectionVerseIndices.isEmpty ? null : _openFullText,
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
    unawaited(_usageMetrics.trackEvent(
      eventName: 'open_full_text_from_daily',
      textId: 'bodhicaryavatara',
      mode: 'daily',
      sectionPath: _sectionPath,
      sectionTitle: _sectionTitle,
      verseRef: _sectionRefs.isNotEmpty ? _sectionRefs.first : null,
      properties: {
        'refs_count': _sectionRefs.length,
      },
    ));
    final sorted = _sectionVerseIndices.toList()..sort();
    final firstIndex = sorted.first;
    final initialSegmentRef = _initialSegmentRefForFirstIndex(firstIndex);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadScreen(
          textId: widget.textId,
          title: widget.title,
          scrollToVerseIndex: firstIndex,
          highlightSectionIndices: _sectionVerseIndices,
          initialSegmentRef: initialSegmentRef,
        ),
      ),
    );
  }

  String? _initialSegmentRefForFirstIndex(int firstIndex) {
    if (_sectionRefs.isEmpty) return null;
    final indexForRef = widget.verseIndexForRef ??
        (ref) => _verseService.getIndexForRefWithFallback(widget.textId, ref);
    String? firstMatchingRef;
    for (final ref in _sectionRefs) {
      final idx = indexForRef(ref);
      if (idx != firstIndex) continue;
      firstMatchingRef ??= ref;
      if (VerseService.segmentSuffixPattern.hasMatch(ref)) {
        return ref;
      }
    }
    return firstMatchingRef;
  }
}
