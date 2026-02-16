import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'bcv/bcv_chapters_panel.dart';
import 'bcv/bcv_read_constants.dart';
import 'bcv/bcv_section_slider.dart';
import '../../services/bcv_verse_service.dart';
import '../../services/commentary_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';

/// Read screen for Bodhicaryavatara: main area with full text, right-side panels for chapters, section overview, and breadcrumb.
/// Optional [scrollToVerseIndex] scrolls to the exact verse after first frame.
/// Optional [highlightSectionIndices] highlights all verses in that section (e.g. from Daily).
class BcvReadScreen extends StatefulWidget {
  const BcvReadScreen({
    super.key,
    this.scrollToVerseIndex,
    this.highlightSectionIndices,
    this.title = 'Bodhicaryavatara',
    this.onSectionNavigateForTest,
  });

  final int? scrollToVerseIndex;

  /// When provided (e.g. from Daily "Full text"), these verses are highlighted as one section.
  final Set<int>? highlightSectionIndices;
  final String title;

  /// Test-only: called when arrow-key navigation selects a section. Receives (sectionPath, firstVerseRef).
  /// Enables automated verification that key-down does not skip verses (e.g. 6.49 -> 6.50, not 6.52).
  final void Function(String sectionPath, String firstVerseRef)? onSectionNavigateForTest;

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

  /// When set (after tapping a verse), scroll to this verse on next frame then clear.
  int? _scrollToVerseIndexAfterTap;

  /// Verses to highlight (set when arriving from Daily or when user taps a verse); cleared on reload.
  Set<int>? _highlightVerseIndices = {};

  /// Commentary for the currently selected verse group (loaded on tap); null if none or not loaded.
  CommentaryEntry? _commentaryEntryForSelected;

  /// When true, show commentary inline below the verses (instead of modal).
  bool _commentaryExpanded = false;
  final _commentaryService = CommentaryService.instance;
  final _hierarchyService = VerseHierarchyService.instance;

  /// Verse index currently in view (for breadcrumb). Null until first visibility.
  int? _visibleVerseIndex;

  /// Section hierarchy for the visible verse. Each has 'section' and 'title'.
  List<Map<String, String>> _breadcrumbHierarchy = [];

  /// Verse indices belonging to the current section (for faint box highlight).
  Set<int>? _currentSectionVerseIndices = {};

  /// Cache: section path -> verse indices (avoids recomputing on same section).
  final Map<String, Set<int>> _sectionVerseIndicesCache = {};
  Timer? _visibilityDebounceTimer;

  /// Incremented on every programmatic navigation. Async visibility handlers check this before applying.
  int _syncGeneration = 0;

  /// True while programmatic scroll (section tap, arrow keys) is animating. Blocks visibility updates entirely.
  bool _isProgrammaticNavigation = false;

  /// After programmatic nav clears, we still ignore visibility updates until this time.
  /// Prevents scroll-settle visibility from overwriting the key-down highlight.
  DateTime? _programmaticNavCooldownUntil;

  /// Per-verse visibility (0–1). We pick the verse with highest visibility = most centered in viewport.
  final Map<String, double> _verseVisibility = {};

  /// Animated section overlay: rect we're sliding from and to.
  Rect? _sectionOverlayRectFrom;
  Rect? _sectionOverlayRectTo;
  int _sectionOverlayAnimationId = 0;
  int _sectionOverlayMeasureRetries = 0;
  final Map<int, GlobalKey> _verseKeys = {};
  final Map<String, GlobalKey> _verseSegmentKeys = {};
  final GlobalKey _scrollContentKey = GlobalKey();
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _sectionSliderScrollController = ScrollController();

  /// Incremented on each section slider scroll request. Stale retries check this.
  int _sectionSliderScrollRequestId = 0;

  bool _breadcrumbCollapsed = false;
  bool _sectionSliderCollapsed = false;
  bool _chaptersPanelCollapsed = false;

  final FocusNode _sectionOverviewFocusNode = FocusNode();

  double _rightPanelsWidth = 360;
  double _chaptersPanelHeight = 80;
  double _breadcrumbPanelHeight = 120;
  double _sectionPanelHeight = 220;

  Set<int> get _highlightSet => _highlightVerseIndices ?? const {};

  bool get _hasInitialHighlight =>
      widget.highlightSectionIndices != null &&
      widget.highlightSectionIndices!.isNotEmpty;

  /// Index of the verse that should have the scroll key (for ensureVisible). Null if none.
  int? get _scrollTargetVerseIndex {
    if (_scrollToVerseIndexAfterTap != null) return _scrollToVerseIndexAfterTap;
    if (_highlightSet.isNotEmpty) {
      return _highlightSet.reduce((a, b) => a < b ? a : b);
    }
    if (widget.scrollToVerseIndex != null) return widget.scrollToVerseIndex;
    if (_hasInitialHighlight) {
      return widget.highlightSectionIndices!.reduce((a, b) => a < b ? a : b);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.scrollToVerseIndex != null ||
        _hasInitialHighlight) {
      _scrollToVerseKey = GlobalKey();
    }
    _load();
  }

  @override
  void dispose() {
    _visibilityDebounceTimer?.cancel();
    _mainScrollController.dispose();
    _sectionSliderScrollController.dispose();
    _sectionOverviewFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _highlightVerseIndices = {};
      _currentSectionVerseIndices = {};
      _sectionVerseIndicesCache.clear();
      _sectionOverlayRectFrom = null;
      _sectionOverlayRectTo = null;
      _sectionOverlayMeasureRetries = 0;
      _verseVisibility.clear();
      _commentaryEntryForSelected = null;
      _commentaryExpanded = false;
      _syncGeneration = 0;
      _isProgrammaticNavigation = false;
      _sectionSliderScrollRequestId = 0;
    });
    try {
      final chapters = await _verseService.getChapters();
      final verses = _verseService.getVerses();
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _verses = verses;
          _loading = false;
          if (widget.highlightSectionIndices != null &&
              widget.highlightSectionIndices!.isNotEmpty) {
            _highlightVerseIndices =
                Set<int>.from(widget.highlightSectionIndices!);
          } else if (widget.scrollToVerseIndex != null) {
            _highlightVerseIndices = {widget.scrollToVerseIndex!};
          }
          for (final c in chapters) {
            _chapterKeys[c.number] = GlobalKey();
          }
        });
        if (widget.scrollToVerseIndex != null && _scrollToVerseKey != null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToVerseWidget());
        }
        if (widget.highlightSectionIndices != null &&
            _highlightSet.isNotEmpty) {
          _loadCommentaryForHighlightedSection();
        }
        _hierarchyService.getHierarchyForVerse('1.1'); // Preload hierarchy map
        _setInitialBreadcrumb();
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
      Scrollable.ensureVisible(key!.currentContext!,
          alignment: 0.0, duration: const Duration(milliseconds: 300));
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
    if (_highlightSet.isEmpty) return;
    final firstIndex =
        _highlightSet.reduce((a, b) => a < b ? a : b);
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
    if (_highlightSet.isEmpty) return [];
    final sorted = _highlightSet.toList()..sort();
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

  /// The section run currently shown (the one containing the visible verse). Used for overlay measurement.
  List<int>? get _activeSectionRun {
    final sectionRuns = _getSectionRuns();
    final visibleIdx = _visibleVerseIndex ?? _scrollTargetVerseIndex;
    if (visibleIdx == null || sectionRuns.isEmpty) return null;
    for (final run in sectionRuns) {
      if (run.contains(visibleIdx)) return run;
    }
    return null;
  }

  /// Measure the rect of the active section run and animate the overlay to it.
  void _measureAndUpdateSectionOverlay() {
    final run = _activeSectionRun;
    final stackContext = _scrollContentKey.currentContext;
    if (stackContext == null) return;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;

    if (run == null || run.isEmpty) {
      if (_sectionOverlayRectTo != null) {
        setState(() {
          _sectionOverlayRectFrom = _sectionOverlayRectTo;
          _sectionOverlayRectTo = null;
          _sectionOverlayAnimationId++;
        });
      }
      return;
    }

    Rect? measured;
    const padH = 12.0;
    const padV = 8.0;
    final currentPath = _breadcrumbHierarchy.isNotEmpty
        ? (_breadcrumbHierarchy.last['section'] ??
            _breadcrumbHierarchy.last['path'] ??
            '')
        : '';
    for (final idx in run) {
      final ref = _verseService.getVerseRef(idx);
      GlobalKey? key;
      if (ref != null &&
          RegExp(r'^\d+\.\d+$').hasMatch(ref) &&
          currentPath.isNotEmpty) {
        final segments =
            _hierarchyService.getSplitVerseSegmentsSync(ref);
        if (segments.length >= 2) {
          final matching = segments
              .where((s) => s.sectionPath == currentPath)
              .toList();
          if (matching.length == 1) {
            final segIdx = segments.indexOf(matching.single);
            key = segIdx == 0
                ? _verseKeys[idx]
                : _verseSegmentKeys['${idx}_$segIdx'];
          }
        }
      }
      key ??= _verseKeys[idx];
      if (key?.currentContext == null) continue;
      final verseBox = key!.currentContext!.findRenderObject() as RenderBox?;
      if (verseBox == null || !verseBox.hasSize) continue;
      final topLeft = verseBox.localToGlobal(Offset.zero, ancestor: stackBox);
      final bottomRight = verseBox.localToGlobal(
        Offset(verseBox.size.width, verseBox.size.height),
        ancestor: stackBox,
      );
      final verseRect = Rect.fromPoints(topLeft, bottomRight);
      final padded = Rect.fromLTRB(
        verseRect.left - padH,
        verseRect.top - padV,
        verseRect.right + padH,
        verseRect.bottom + padV,
      );
      measured = measured == null ? padded : measured.expandToInclude(padded);
    }
    if (measured == null) {
      if (_sectionOverlayMeasureRetries < BcvReadConstants.maxSectionOverlayMeasureRetries) {
        _sectionOverlayMeasureRetries++;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _measureAndUpdateSectionOverlay();
        });
      }
      return;
    }
    _sectionOverlayMeasureRetries = 0;

    // Use full content width (match the SizedBox(width: double.infinity) verse containers)
    final contentWidth = stackBox.size.width;
    final clamped =
        Rect.fromLTWH(0, measured.top, contentWidth, measured.height);

    final prevTo = _sectionOverlayRectTo;
    if (prevTo != null && _rectApproxEquals(prevTo, clamped)) return;

    setState(() {
      _sectionOverlayRectFrom = prevTo ?? clamped;
      _sectionOverlayRectTo = clamped;
      _sectionOverlayAnimationId++;
    });
  }

  bool _rectApproxEquals(Rect a, Rect b, [double epsilon = 2]) {
    return (a.left - b.left).abs() < epsilon &&
        (a.top - b.top).abs() < epsilon &&
        (a.width - b.width).abs() < epsilon &&
        (a.height - b.height).abs() < epsilon;
  }

  /// Consecutive verse indices in current section but NOT in highlight (for faint box).
  List<List<int>> _getSectionRuns() {
    final section = _currentSectionVerseIndices ?? {};
    final highlight = _highlightSet;
    final sectionOnly = section.difference(highlight).toList()..sort();
    if (sectionOnly.isEmpty) return [];
    final runs = <List<int>>[];
    var current = [sectionOnly.first];
    for (var i = 1; i < sectionOnly.length; i++) {
      if (sectionOnly[i] == current.last + 1) {
        current.add(sectionOnly[i]);
      } else {
        runs.add(current);
        current = [sectionOnly[i]];
      }
    }
    runs.add(current);
    return runs;
  }

  Future<void> _onVerseTap(int globalIndex) async {
    // If clicking a verse that's already highlighted, clear selection
    if (_highlightSet.contains(globalIndex)) {
      setState(() {
        _highlightVerseIndices = {};
        _commentaryEntryForSelected = null;
        _commentaryExpanded = false;
      });
      return;
    }

    // Get the verse ref and load commentary
    final ref = _verseService.getVerseRef(globalIndex);
    if (ref == null) return;

    final entry = await _commentaryService.getCommentaryForRef(ref);
    if (!mounted) return;

    // If this verse has no commentary, just highlight it alone and hide any open commentary
    if (entry == null) {
      setState(() {
        _highlightVerseIndices = {globalIndex};
        _commentaryEntryForSelected = null;
        _commentaryExpanded = false;
      });
      _scrollToVerseIndex(globalIndex);
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
    // Highlight only the consecutive run containing the tapped verse (avoids 2+ boxes when block has gaps)
    final sorted = verseIndicesInBlock.toList()..sort();
    final highlightRun = <int>{};
    var runStart = 0;
    for (var i = 0; i <= sorted.length; i++) {
      if (i < sorted.length && (i == 0 || sorted[i] == sorted[i - 1] + 1)) {
        continue; // same run
      }
      final run = sorted.sublist(runStart, i);
      if (run.contains(globalIndex)) {
        highlightRun.addAll(run);
        break;
      }
      runStart = i;
    }
    if (highlightRun.isEmpty) highlightRun.add(globalIndex);
    final firstInSection = highlightRun.reduce((a, b) => a < b ? a : b);

    setState(() {
      _highlightVerseIndices = highlightRun;
      _commentaryEntryForSelected = entry;
      _commentaryExpanded = false;
    });
    _scrollToVerseIndex(firstInSection);
  }

  /// Strip verse ref lines and verse text from commentary body so we show verses once at top.
  String _commentaryOnly(CommentaryEntry entry) {
    String body = entry.commentaryText;
    for (final ref in entry.refsInBlock) {
      // Remove line that is just the ref (e.g. "2.60")
      body = body.replaceAll(
          RegExp('^${RegExp.escape(ref)}\\s*\$', multiLine: true), '');
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

  void _toggleCommentaryExpanded() {
    setState(() {
      _commentaryExpanded = !_commentaryExpanded;
    });
  }

  void _setInitialBreadcrumb() {
    final initialIndex = _scrollTargetVerseIndex ?? 0;
    if (initialIndex >= _verses.length) return;
    _hierarchyService.getHierarchyForVerseIndex(initialIndex).then((hierarchy) {
      if (!mounted) return;
      final sectionPath = hierarchy.isNotEmpty
          ? (hierarchy.last['section'] ?? hierarchy.last['path'] ?? '')
          : '';
      var indices = _verseIndicesForSection(sectionPath);
      if (indices.isEmpty && sectionPath.isNotEmpty) {
        indices = {initialIndex};
      }
      final indicesWithVisible = {...indices, initialIndex};
      _applySectionState(
        hierarchy: hierarchy,
        verseIndices: indicesWithVisible,
        verseIndex: initialIndex,
      );
    });
  }

  /// Extracts the last segment of the path as the sibling number (e.g. "1.1.3.2" -> "2").
  String _sectionNumberForDisplay(String section) {
    if (section.isEmpty) return '';
    final parts = section.split('.');
    return parts.last;
  }

  /// Resolve verse indices from section path (refs -> indices, handling split verses).
  Set<int> _verseIndicesForSection(String sectionPath) {
    if (sectionPath.isEmpty) return {};
    final cached = _sectionVerseIndicesCache[sectionPath];
    if (cached != null && cached.isNotEmpty) return cached;
    final refs = _hierarchyService.getVerseRefsForSectionSync(sectionPath);
    final indices = <int>{};
    for (final ref in refs) {
      var i = _verseService.getIndexForRef(ref);
      if (i == null && RegExp(r'[a-d]+$').hasMatch(ref)) {
        i = _verseService
            .getIndexForRef(ref.replaceAll(RegExp(r'[a-d]+$'), ''));
      }
      if (i != null) indices.add(i);
    }
    if (indices.isNotEmpty) _sectionVerseIndicesCache[sectionPath] = indices;
    return indices;
  }

  /// Unified apply: updates breadcrumb, section verses, overlay, slider. All sync update paths call this.
  /// If [supersedeGen] is set, applies only if it equals current _syncGeneration (discards stale async).
  void _applySectionState({
    required List<Map<String, String>> hierarchy,
    required Set<int> verseIndices,
    required int verseIndex,
    String? segmentRef,
    int? supersedeGen,
  }) {
    if (supersedeGen != null && supersedeGen != _syncGeneration) return;
    setState(() {
      _breadcrumbHierarchy = hierarchy;
      _currentSectionVerseIndices = verseIndices;
      _visibleVerseIndex = verseIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureAndUpdateSectionOverlay();
      _scrollSectionSliderToCurrent();
    });
  }

  Future<void> _onBreadcrumbSectionTap(Map<String, String> item) async {
    final section = item['section'] ?? item['path'] ?? '';
    if (section.isEmpty) return;

    _syncGeneration++;
    _isProgrammaticNavigation = true;
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = null;

    final hierarchy = _hierarchyService.getHierarchyForSectionSync(section);
    if (hierarchy.isNotEmpty) {
      final verseIndices = _verseIndicesForSection(section);
      _applySectionState(
        hierarchy: hierarchy,
        verseIndices: verseIndices,
        verseIndex: verseIndices.isNotEmpty
            ? verseIndices.reduce((a, b) => a < b ? a : b)
            : 0,
      );
    }

    // Ensure hierarchy loaded; then resolve first verse, preferring current chapter
    // when section has duplicate titles across chapters (e.g. "Abandoning objections")
    await _hierarchyService.getFirstVerseForSection(section);
    final preferredChapter = _currentChapterNumber;
    final firstVerseRef =
        _hierarchyService.getFirstVerseForSectionInChapterSync(
            section, preferredChapter) ??
        _hierarchyService.getFirstVerseForSectionSync(section);
    if (firstVerseRef == null || firstVerseRef.isEmpty) return;
    var verseIndex = _verseService.getIndexForRef(firstVerseRef);
    if (verseIndex == null && RegExp(r'[a-d]+$').hasMatch(firstVerseRef)) {
      verseIndex = _verseService.getIndexForRef(
        firstVerseRef.replaceAll(RegExp(r'[a-d]+$'), ''),
      );
    }
    if (verseIndex == null) return;
    _visibleVerseIndex = verseIndex;
    _scrollToVerseIndex(verseIndex);
  }

  void _scrollToVerseIndex(int index) {
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = null;
    _isProgrammaticNavigation = true;
    _scrollToVerseIndexAfterTap = index;
    _scrollToVerseKey ??= GlobalKey();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToVerseWidget();
      setState(() => _scrollToVerseIndexAfterTap = null);
      _clearProgrammaticNavigationAfterScrollSettles();
    });
  }

  /// Clears _isProgrammaticNavigation only after the scroll animation finishes and
  /// visibility callbacks have settled. Prevents race where visibility updates
  /// overwrite the key-nav highlight.
  void _clearProgrammaticNavigationAfterScrollSettles() {
    void doClear() {
      if (!mounted) return;
      // Cancel any pending visibility timer
      _visibilityDebounceTimer?.cancel();
      _visibilityDebounceTimer = null;
      _isProgrammaticNavigation = false;
      // Cooldown: keep ignoring visibility-driven highlights for 500ms after scroll
      // settles. Prevents scroll-settle callbacks from overwriting key-nav highlight.
      _programmaticNavCooldownUntil =
          DateTime.now().add(const Duration(milliseconds: 500));
      _measureAndUpdateSectionOverlay();
    }

    final pos = _mainScrollController.hasClients
        ? _mainScrollController.position
        : null;
    if (pos != null && pos.isScrollingNotifier.value) {
      VoidCallback? listener;
      listener = () {
        if (!mounted || pos.isScrollingNotifier.value) return;
        pos.isScrollingNotifier.removeListener(listener!);
        // Buffer for visibility debounce (150ms) + a frame for layout
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          doClear();
        });
      };
      pos.isScrollingNotifier.addListener(listener);
      // Fallback: clear after 1.5s in case scroll never settles
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        pos.isScrollingNotifier.removeListener(listener!);
        doClear();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 350), doClear);
    }
  }

  void _onVerseVisibilityChanged(int verseIndex, double visibility,
      {String? segmentRef}) {
    if (_isProgrammaticNavigation) return;
    if (_programmaticNavCooldownUntil != null &&
        DateTime.now().isBefore(_programmaticNavCooldownUntil!)) {
      return;
    }
    final key = segmentRef != null ? '${verseIndex}_$segmentRef' : '$verseIndex';
    if (visibility < 0.05) {
      _verseVisibility.remove(key);
      return;
    }
    _verseVisibility[key] = visibility;
    _visibilityDebounceTimer?.cancel();
    // Capture generation when timer STARTS, not when it fires
    final capturedGen = _syncGeneration;
    _visibilityDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      _visibilityDebounceTimer = null;
      if (!mounted || _verseVisibility.isEmpty || _isProgrammaticNavigation) return;
      if (_programmaticNavCooldownUntil != null &&
          DateTime.now().isBefore(_programmaticNavCooldownUntil!)) return;
      // Check if generation changed while timer was pending
      if (capturedGen != _syncGeneration) return;
      final picked = _pickVerseClosestToViewportCenter();
      if (picked == null) return;
      final (pickedIdx, pickedSegRef) = picked;
      final future = pickedSegRef != null
          ? _hierarchyService.getHierarchyForVerse(pickedSegRef)
          : _hierarchyService.getHierarchyForVerseIndex(pickedIdx);
      future.then((hierarchy) {
        if (!mounted || capturedGen != _syncGeneration) return;
        final sectionPath = hierarchy.isNotEmpty
            ? (hierarchy.last['section'] ?? hierarchy.last['path'] ?? '')
            : '';
        var indices = _verseIndicesForSection(sectionPath);
        if (indices.isEmpty && sectionPath.isNotEmpty) {
          indices = {pickedIdx};
        }
        final indicesWithVisible = {...indices, pickedIdx};
        setState(() {
          if (_highlightSet.isNotEmpty && !_highlightSet.contains(pickedIdx)) {
            _highlightVerseIndices = {};
            _commentaryEntryForSelected = null;
            _commentaryExpanded = false;
          }
        });
        _applySectionState(
          hierarchy: hierarchy,
          verseIndices: indicesWithVisible,
          verseIndex: pickedIdx,
          segmentRef: pickedSegRef,
          supersedeGen: capturedGen,
        );
      });
    });
  }

  /// Picks the verse (or segment) whose center is closest to the viewport center.
  /// Returns (verseIndex, segmentRef?) or null if no verse can be measured.
  (int, String?)? _pickVerseClosestToViewportCenter() {
    if (_verseVisibility.isEmpty) return null;
    final pos = _mainScrollController.hasClients
        ? _mainScrollController.position
        : null;
    if (pos == null) {
      final best =
          _verseVisibility.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final parts = best.key.split('_');
      final verseToUse = int.tryParse(parts.first) ?? 0;
      final segRef = parts.length > 1 ? parts.sublist(1).join('_') : null;
      return (verseToUse, segRef);
    }
    final scrollOffset = pos.pixels;
    final viewportHeight = pos.viewportDimension;
    final viewportCenterY = scrollOffset + viewportHeight / 2;

    final stackContext = _scrollContentKey.currentContext;
    if (stackContext == null) return null;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return null;

    String? bestKey;
    double bestDist = double.infinity;

    for (final entry in _verseVisibility.entries) {
      if (entry.value < 0.05) continue;
      final parts = entry.key.split('_');
      final idx = int.tryParse(parts.first);
      if (idx == null) continue;
      final segRef = parts.length > 1 ? parts.sublist(1).join('_') : null;
      GlobalKey? gk = segRef != null
          ? _verseSegmentKeys['${idx}_${_segmentIndexForRef(idx, segRef)}']
          : _verseKeys[idx];
      gk ??= _verseKeys[idx];
      if (gk?.currentContext == null) continue;
      final box = gk!.currentContext!.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final topLeft = box.localToGlobal(Offset.zero, ancestor: stackBox);
      final verseCenterY = topLeft.dy + box.size.height / 2;
      final dist = (verseCenterY - viewportCenterY).abs();
      if (dist < bestDist) {
        bestDist = dist;
        bestKey = entry.key;
      }
    }
    if (bestKey == null) return null;
    final parts = bestKey.split('_');
    final verseToUse = int.tryParse(parts.first) ?? 0;
    final segRef = parts.length > 1 ? parts.sublist(1).join('_') : null;
    return (verseToUse, segRef);
  }

  int _segmentIndexForRef(int verseIndex, String segmentRef) {
    final ref = _verseService.getVerseRef(verseIndex);
    if (ref == null) return 0;
    final segments = _hierarchyService.getSplitVerseSegmentsSync(ref);
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].ref == segmentRef) return i;
    }
    return 0;
  }

  void _scrollSectionSliderToCurrent() {
    if (_breadcrumbHierarchy.isEmpty) return;
    final currentPath = _breadcrumbHierarchy.last['section'] ??
        _breadcrumbHierarchy.last['path'] ??
        '';
    if (currentPath.isEmpty) return;
    _sectionSliderScrollRequestId++;
    final requestId = _sectionSliderScrollRequestId;
    final flat = _hierarchyService.getFlatSectionsSync();
    final idx = flat.indexWhere((s) => s.path == currentPath);
    if (idx < 0) return;
    final viewportHeight =
        BcvReadConstants.sectionSliderLineHeight * BcvReadConstants.sectionSliderVisibleLines;
    final targetOffset = (idx * BcvReadConstants.sectionSliderLineHeight) -
        (viewportHeight / 2) +
        (BcvReadConstants.sectionSliderLineHeight / 2);
    final maxOffset = (flat.length * BcvReadConstants.sectionSliderLineHeight - viewportHeight)
        .clamp(0.0, double.infinity);
    final maxOffsetSafe = maxOffset.isFinite ? maxOffset : 0.0;
    final clamped = targetOffset.clamp(0.0, maxOffsetSafe).toDouble();
    void doScroll() {
      if (!mounted || requestId != _sectionSliderScrollRequestId) return;
      if (!_sectionSliderScrollController.hasClients) return;
      _sectionSliderScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    if (_sectionSliderScrollController.hasClients) {
      doScroll();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        doScroll();
        if (!_sectionSliderScrollController.hasClients && mounted) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && requestId == _sectionSliderScrollRequestId) {
              doScroll();
            }
          });
        }
      });
    }
  }

  /// Inline commentary panel (inserted below verses in the main scroll). Visually distinct from root text.
  /// Uses a muted sage/green-grey palette (Dechen-style) and is indented like a subsection.
  static const Color _commentaryBg = AppColors.commentaryBg;
  static const Color _commentaryBorder = AppColors.commentaryBorder;
  static const Color _commentaryHeader = AppColors.commentaryHeader;

  Widget _buildInlineCommentaryPanel(CommentaryEntry entry) {
    final verseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Crimson Text',
          fontSize: 18,
          height: 1.8,
          color: AppColors.textDark,
        );
    final headingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'Lora',
          color: _commentaryHeader,
        );
    final commentaryOnly = _commentaryOnly(entry);
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 8, bottom: 16, right: 0),
      child: Container(
        decoration: BoxDecoration(
          color: _commentaryBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _commentaryBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: _commentaryBorder.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: "Commentary" label + close
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _commentaryHeader.withValues(alpha: 0.15),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book, size: 20, color: _commentaryHeader),
                  const SizedBox(width: 8),
                  Text(
                    'Commentary',
                    style: headingStyle?.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _toggleCommentaryExpanded,
                    style: TextButton.styleFrom(
                      foregroundColor: _commentaryHeader,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.refsInBlock.length == 1) ...[
                    Text(
                      'Verse ${entry.refsInBlock.single}',
                      style: headingStyle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _verseService.getIndexForRef(entry.refsInBlock.single) !=
                              null
                          ? (_verseService.getVerseAt(
                                _verseService
                                    .getIndexForRef(entry.refsInBlock.single)!,
                              ) ??
                              '')
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
                      final text =
                          idx != null ? _verseService.getVerseAt(idx) : null;
                      if (text == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verse $ref',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'Lora',
                                    color: _commentaryHeader,
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
                          color: AppColors.textDark,
                        ),
                  ),
                ],
              ),
            ),
          ],
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _chaptersPanelCollapsed
                  ? Icons.menu_book
                  : Icons.menu_book_outlined,
              color: AppColors.textDark,
            ),
            tooltip: _chaptersPanelCollapsed ? 'Show Chapters' : 'Hide Chapters',
            onPressed: () => setState(
                () => _chaptersPanelCollapsed = !_chaptersPanelCollapsed),
          ),
          IconButton(
            icon: Icon(
              _breadcrumbCollapsed
                  ? Icons.account_tree
                  : Icons.account_tree_outlined,
              color: AppColors.textDark,
            ),
            tooltip: _breadcrumbCollapsed
                ? 'Show Breadcrumb Trail'
                : 'Hide Breadcrumb Trail',
            onPressed: () =>
                setState(() => _breadcrumbCollapsed = !_breadcrumbCollapsed),
          ),
          IconButton(
            icon: Icon(
              _sectionSliderCollapsed ? Icons.list : Icons.list_alt,
              color: AppColors.textDark,
            ),
            tooltip: _sectionSliderCollapsed
                ? 'Show Section Overview'
                : 'Hide Section Overview',
            onPressed: () => setState(
                () => _sectionSliderCollapsed = !_sectionSliderCollapsed),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Last time we handled arrow navigation. Used to debounce key repeat / double-fire.
  DateTime? _lastArrowNavTime;

  /// Handler for reader pane: always navigates by verse order (new set of verses).
  KeyEventResult _handleReaderKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _debouncedArrowNav(() => _scrollToAdjacentSection(1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _debouncedArrowNav(() => _scrollToAdjacentSection(-1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Handler for section overview: uses leaf-based nav (same as reader) so arrow keys
  /// always move through sections in verse order without skipping.
  KeyEventResult _handleSectionOverviewKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _debouncedArrowNav(() => _scrollToAdjacentSection(1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _debouncedArrowNav(() => _scrollToAdjacentSection(-1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Run [fn] only if enough time has passed since last arrow nav (debounce 200ms).
  void _debouncedArrowNav(void Function() fn) {
    final now = DateTime.now();
    if (_lastArrowNavTime != null &&
        now.difference(_lastArrowNavTime!).inMilliseconds < 200) {
      return;
    }
    _lastArrowNavTime = now;
    fn();
  }

  /// Navigate to previous (direction -1) or next (direction 1) section.
  /// Reader pane: uses leaf sections only so each key down moves exactly one
  /// "lowest level" section forward (no jumps to parents, no skipping).
  void _scrollToAdjacentSection(int direction) {
    final leafOrdered = _hierarchyService.getLeafSectionsByVerseOrderSync();
    if (leafOrdered.isEmpty) return;

    final visibleIdx = _visibleVerseIndex ?? _scrollTargetVerseIndex;
    final verseRef = visibleIdx != null
        ? _verseService.getVerseRef(visibleIdx)
        : null;
    final currentPath = _currentSectionPath;

    var currentIdx = -1;
    if (currentPath.isNotEmpty) {
      currentIdx = leafOrdered.indexWhere((s) => s.path == currentPath);
    }
    if (currentIdx < 0 && verseRef != null && verseRef.isNotEmpty) {
      final hierarchy = _hierarchyService.getHierarchyForVerseSync(verseRef);
      if (hierarchy.isNotEmpty) {
        final leafPath = hierarchy.last['section'] ?? hierarchy.last['path'] ?? '';
        if (leafPath.isNotEmpty) {
          currentIdx = leafOrdered.indexWhere((s) => s.path == leafPath);
        }
      }
    }
    int newIdx;
    if (currentIdx >= 0) {
      newIdx = currentIdx + direction;
    } else if (verseRef != null && verseRef.isNotEmpty) {
      newIdx = _hierarchyService.findAdjacentSectionIndex(
        leafOrdered,
        verseRef,
        direction: direction,
      );
    } else {
      return;
    }

    if (newIdx < 0 || newIdx >= leafOrdered.length) return;
    final section = leafOrdered[newIdx];
    final firstRef =
        _hierarchyService.getFirstVerseForSectionSync(section.path) ?? '';
    widget.onSectionNavigateForTest?.call(section.path, firstRef);
    _onBreadcrumbSectionTap({
      'section': section.path,
      'path': section.path,
      'title': section.title,
    });
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load text',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
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

    return _buildMainContent();
  }

  int? get _currentChapterNumber {
    final idx = _visibleVerseIndex ?? _scrollTargetVerseIndex;
    if (idx == null) return null;
    for (final ch in _chapters) {
      if (idx >= ch.startVerseIndex && idx < ch.endVerseIndex) {
        return ch.number;
      }
    }
    return null;
  }

  Widget _buildChaptersPanel({double? height}) {
    return BcvChaptersPanel(
      chapters: _chapters,
      currentChapterNumber: _currentChapterNumber,
      onChapterTap: _scrollToChapter,
      height: height,
    );
  }

  String get _currentSectionPath => _breadcrumbHierarchy.isNotEmpty
      ? (_breadcrumbHierarchy.last['section'] ??
          _breadcrumbHierarchy.last['path'] ??
          '')
      : '';

  Widget _buildSectionSlider({double? height, required bool collapsed}) {
    final flat = _hierarchyService.getFlatSectionsSync();
    final slider = BcvSectionSlider(
      flatSections: flat,
      currentPath: _currentSectionPath,
      onSectionTap: _onBreadcrumbSectionTap,
      sectionNumberForDisplay: _sectionNumberForDisplay,
      scrollController: _sectionSliderScrollController,
      height: height,
    );
    return Focus(
      focusNode: _sectionOverviewFocusNode,
      skipTraversal: collapsed,
      onKeyEvent: _handleSectionOverviewKeyEvent,
      child: Listener(
        onPointerDown: (_) => _sectionOverviewFocusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: slider,
      ),
    );
  }

  Widget _buildVerticalResizeHandle({
    required ValueChanged<double> onDragDelta,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => setState(() => onDragDelta(d.delta.dy)),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: Container(
          height: 6,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavSection(
    bool collapsed,
    Widget Function() full,
    VoidCallback onExpand,
    VoidCallback onCollapse,
    String subtitle,
    String label, {
    double? contentHeight,
  }) {
    Widget expandedContent = full();
    if (contentHeight != null && contentHeight > 0) {
      final h = contentHeight.clamp(BcvReadConstants.panelMinHeight, 400.0).toDouble();
      expandedContent = SizedBox(
        height: h,
        child: SingleChildScrollView(child: expandedContent),
      );
    }
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(
            label: label,
            subtitle: subtitle,
            expanded: true,
            onCollapse: onCollapse,
          ),
          expandedContent,
        ],
      ),
      secondChild: _buildCollapsedStrip(
        label: label,
        onTap: onExpand,
        subtitle: subtitle,
        onExpand: onExpand,
      ),
    );
  }

  Widget _buildPanelHeader({
    required String label,
    required String subtitle,
    required bool expanded,
    required VoidCallback onCollapse,
  }) {
    return Material(
      color: AppColors.cardBeige,
      child: InkWell(
        onTap: onCollapse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.expand_less, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle.isNotEmpty ? '$label: $subtitle' : label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.textDark,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedStrip({
    required String label,
    required VoidCallback onTap,
    required String subtitle,
    required VoidCallback onExpand,
  }) {
    return Material(
      color: AppColors.cardBeige,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.expand_more, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle.isNotEmpty ? subtitle : 'Tap to show $label',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.textDark,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.expand_more,
                    size: 20, color: AppColors.primary),
                tooltip: 'Expand',
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
                onPressed: onExpand,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelsColumn() {
    final breadcrumbSubtitle = _breadcrumbHierarchy.isNotEmpty
        ? (_breadcrumbHierarchy.last['title'] ?? '')
        : '';
    String chaptersSubtitle = '';
    final curCh = _currentChapterNumber;
    if (curCh != null) {
      for (final c in _chapters) {
        if (c.number == curCh) {
          chaptersSubtitle = c.title;
          break;
        }
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavSection(
          _chaptersPanelCollapsed,
          () => _buildChaptersPanel(height: _chaptersPanelHeight),
          () => setState(() => _chaptersPanelCollapsed = false),
          () => setState(() => _chaptersPanelCollapsed = true),
          chaptersSubtitle,
          'Chapters',
        ),
        _buildVerticalResizeHandle(onDragDelta: (dy) {
          setState(() {
            if (_chaptersPanelHeight + dy >= BcvReadConstants.panelMinHeight &&
                _sectionPanelHeight - dy >= BcvReadConstants.panelMinHeight) {
              _chaptersPanelHeight += dy;
              _sectionPanelHeight -= dy;
            }
          });
        }),
        _buildNavSection(
          _sectionSliderCollapsed,
          () => _buildSectionSlider(
            height: _sectionPanelHeight,
            collapsed: _sectionSliderCollapsed,
          ),
          () => setState(() => _sectionSliderCollapsed = false),
          () => setState(() => _sectionSliderCollapsed = true),
          breadcrumbSubtitle,
          'Section Overview',
        ),
        _buildVerticalResizeHandle(onDragDelta: (dy) {
          setState(() {
            if (_sectionPanelHeight + dy >= BcvReadConstants.panelMinHeight &&
                _breadcrumbPanelHeight - dy >= BcvReadConstants.panelMinHeight) {
              _sectionPanelHeight += dy;
              _breadcrumbPanelHeight -= dy;
            }
          });
        }),
        _buildNavSection(
          _breadcrumbCollapsed,
          _buildBreadcrumbBar,
          () => setState(() => _breadcrumbCollapsed = false),
          () => setState(() => _breadcrumbCollapsed = true),
          breadcrumbSubtitle,
          'Breadcrumb Trail',
        ),
      ],
    );
  }

  Widget _buildBreadcrumbBar() {
    if (_breadcrumbHierarchy.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: BcvReadConstants.panelPaddingV,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        border: Border(
          bottom:
              BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: _buildBreadcrumbTrail(),
    );
  }

  Widget _buildBreadcrumbTrail() {
    final baseStyle = BcvSectionSlider.sectionListTextStyle(
      context,
      isCurrent: false,
      isAncestor: false,
    );
    final separatorStyle = baseStyle.copyWith(color: AppColors.mutedBrown);

    final spans = <InlineSpan>[];
    for (var i = 0; i < _breadcrumbHierarchy.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: ' › ', style: separatorStyle));
      }
      final item = _breadcrumbHierarchy[i];
      final isCurrent = i == _breadcrumbHierarchy.length - 1;
      final title = item['title'] ?? '';
      final section = item['section'] ?? item['path'] ?? '';
      final numDisplay = _sectionNumberForDisplay(section);
      final label = numDisplay.isNotEmpty ? '$numDisplay. $title' : title;
      final style = BcvSectionSlider.sectionListTextStyle(
        context,
        isCurrent: isCurrent,
        isAncestor: false,
      );
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _onBreadcrumbSectionTap(item);
      spans.add(
        TextSpan(
          text: label,
          style: style,
          recognizer: recognizer,
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: RichText(
        text: TextSpan(style: baseStyle, children: spans),
        softWrap: true,
      ),
    );
  }

  Widget _buildMainContent() {
    final isLaptop =
        MediaQuery.of(context).size.width >= BcvReadConstants.laptopBreakpoint;
    final scrollContent = Focus(
      autofocus: true,
      onKeyEvent: _handleReaderKeyEvent,
      child: SingleChildScrollView(
            controller: _mainScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Stack(
              key: _scrollContentKey,
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _chapters.map((ch) {
                    final key = _chapterKeys[ch.number];
                    final verseTexts = ch.startVerseIndex < _verses.length
                        ? _verses.sublist(ch.startVerseIndex,
                            ch.endVerseIndex.clamp(0, _verses.length))
                        : <String>[];
                    return RepaintBoundary(
                      child: Column(
                        key: key,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapter ${ch.number}: ${ch.title}',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontFamily: 'Crimson Text',
                                  color: AppColors.textDark,
                                ),
                          ),
                          const SizedBox(height: 24),
                          ...() {
                            final verseStyle =
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontFamily: 'Crimson Text',
                                      fontSize: 18,
                                      height: 1.8,
                                      color: AppColors.textDark,
                                    );
                            // Unified box: same shape, faint (section) vs darker (commentary)
                            BoxDecoration boxDecoration(
                                    {required bool darker}) =>
                                BoxDecoration(
                                  color: darker
                                      ? AppColors.landingBackground
                                          .withValues(alpha: 0.5)
                                      : AppColors.primary
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: darker ? 0.45 : 0.22,
                                    ),
                                    width: 1,
                                  ),
                                );

                            Widget buildVerseContent(int idx, String text,
                                {List<int>? lineRange,
                                int? segmentIndex,
                                String? segmentRef}) {
                              final lines = text.split('\n');
                              final displayText = lineRange != null &&
                                      lineRange.length == 2 &&
                                      lineRange[0] >= 0 &&
                                      lineRange[1] < lines.length
                                  ? lines
                                      .sublist(lineRange[0], lineRange[1] + 1)
                                      .join('\n')
                                  : text;
                              final isSplitSegment =
                                  segmentIndex != null && segmentIndex > 0;
                              if (!isSplitSegment) {
                                _verseKeys[idx] ??= GlobalKey();
                              } else {
                                _verseSegmentKeys['${idx}_$segmentIndex'] ??=
                                    GlobalKey();
                              }
                              final isTargetVerse =
                                  _scrollTargetVerseIndex != null &&
                                      _scrollTargetVerseIndex == idx &&
                                      _scrollToVerseKey != null &&
                                      (segmentIndex ?? 0) == 0;
                              Widget w = GestureDetector(
                                onTap: () => _onVerseTap(idx),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(displayText, style: verseStyle),
                                ),
                              );
                              if (isTargetVerse) {
                                w = KeyedSubtree(
                                    key: _scrollToVerseKey, child: w);
                              }
                              final subtreeKey = isSplitSegment
                                  ? _verseSegmentKeys['${idx}_$segmentIndex']
                                  : _verseKeys[idx];
                              final key = subtreeKey ??
                                  ValueKey('verse_${idx}_seg_$segmentIndex');
                              return VisibilityDetector(
                                key: ValueKey(
                                    'verse_${idx}_${lineRange ?? 'full'}'),
                                onVisibilityChanged: (info) =>
                                    _onVerseVisibilityChanged(
                                        idx, info.visibleFraction,
                                        segmentRef: segmentRef),
                                child: KeyedSubtree(
                                  key: key,
                                  child: w,
                                ),
                              );
                            }

                            /// For ab/cd split: ab = first half of lines, cd = second half.
                            List<int>? lineRangeForSegment(
                                int segmentIndex, int lineCount) {
                              if (lineCount < 2 || segmentIndex > 1) return null;
                              final half = lineCount ~/ 2;
                              if (segmentIndex == 0) {
                                return [0, half - 1];
                              }
                              return [half, lineCount - 1];
                            }

                            Widget wrapInBox(List<int> indices,
                                {required bool darker}) {
                              if (indices.length == 1) {
                                final idx = indices.single;
                                final ref = _verseService.getVerseRef(idx);
                                if (ref != null &&
                                    RegExp(r'^\d+\.\d+$').hasMatch(ref)) {
                                  final segments = _hierarchyService
                                      .getSplitVerseSegmentsSync(ref);
                                  if (segments.length >= 2) {
                                    final text =
                                        idx < _verses.length ? _verses[idx] : '';
                                    final lines = text.split('\n');
                                    if (lines.length >= 2) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (var i = 0;
                                              i < segments.length;
                                              i++)
                                            SizedBox(
                                              width: double.infinity,
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                decoration: boxDecoration(
                                                    darker: darker),
                                                child: buildVerseContent(
                                                  idx,
                                                  text,
                                                  lineRange:
                                                      lineRangeForSegment(
                                                          i, lines.length),
                                                  segmentIndex: i,
                                                  segmentRef: segments[i].ref,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    }
                                  }
                                }
                              }
                              final verseWidgets = indices.map((idx) {
                                final text =
                                    idx < _verses.length ? _verses[idx] : '';
                                return buildVerseContent(idx, text);
                              }).toList();
                              return SizedBox(
                                width: double.infinity,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: boxDecoration(darker: darker),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: verseWidgets,
                                  ),
                                ),
                              );
                            }

                            final children = <Widget>[];
                            final highlightRuns = _getHighlightRuns();
                            final usedInRun = <int>{};

                            List<int>? runContaining(
                                int idx, List<List<int>> runList) {
                              for (final r in runList) {
                                if (r.contains(idx)) return r;
                              }
                              return null;
                            }

                            for (final entry in verseTexts.asMap().entries) {
                              final localIndex = entry.key;
                              final verse = entry.value;
                              final globalIndex =
                                  ch.startVerseIndex + localIndex;

                              if (usedInRun.contains(globalIndex)) continue;

                              final highlightRun =
                                  runContaining(globalIndex, highlightRuns);
                              if (highlightRun != null &&
                                  highlightRun.first == globalIndex) {
                                for (final idx in highlightRun) {
                                  usedInRun.add(idx);
                                }
                                final hasCommentary =
                                    _commentaryEntryForSelected != null;
                                final commentaryEntry =
                                    _commentaryEntryForSelected;
                                children.add(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      wrapInBox(highlightRun, darker: true),
                                      if (hasCommentary) ...[
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: _toggleCommentaryExpanded,
                                          icon: Icon(
                                            _commentaryExpanded
                                                ? Icons.expand_less
                                                : Icons.menu_book,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          label: Text(
                                            _commentaryExpanded
                                                ? 'Hide commentary'
                                                : 'Commentary',
                                            style: const TextStyle(
                                              fontFamily: 'Lora',
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (_commentaryExpanded &&
                                            commentaryEntry != null) ...[
                                          _buildInlineCommentaryPanel(
                                              commentaryEntry),
                                        ],
                                      ],
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                );
                                continue;
                              }

                              // Section highlight is drawn via animated overlay.
                              // For split verses, render as two blocks so overlay can highlight each segment.
                              final ref = _verseService.getVerseRef(globalIndex);
                              final isSplit = ref != null &&
                                  RegExp(r'^\d+\.\d+$').hasMatch(ref) &&
                                  _hierarchyService
                                      .getSplitVerseSegmentsSync(ref)
                                      .length >= 2;
                              if (isSplit) {
                                final segments = _hierarchyService
                                    .getSplitVerseSegmentsSync(ref);
                                final lines = verse.split('\n');
                                if (lines.length >= 2) {
                                  for (var i = 0; i < segments.length; i++) {
                                    final range =
                                        lineRangeForSegment(i, lines.length);
                                    if (range != null) {
                                      children.add(
                                        SizedBox(
                                          width: double.infinity,
                                          child: buildVerseContent(
                                            globalIndex,
                                            verse,
                                            lineRange: range,
                                            segmentIndex: i,
                                            segmentRef: segments[i].ref,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  children.add(
                                    SizedBox(
                                      width: double.infinity,
                                      child: buildVerseContent(
                                          globalIndex, verse),
                                    ),
                                  );
                                }
                              } else {
                                children.add(
                                  SizedBox(
                                    width: double.infinity,
                                    child: buildVerseContent(
                                        globalIndex, verse),
                                  ),
                                );
                              }
                            }
                            return children;
                          }(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (_sectionOverlayRectTo != null)
                  TweenAnimationBuilder<Rect?>(
                    key:
                        ValueKey('section_overlay_$_sectionOverlayAnimationId'),
                    tween: RectTween(
                      begin: _sectionOverlayRectFrom ?? _sectionOverlayRectTo,
                      end: _sectionOverlayRectTo,
                    ),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, rect, child) {
                      if (rect == null) return const SizedBox.shrink();
                      final w = rect.width;
                      final h = rect.height;
                      if (w.isNaN || h.isNaN || w <= 0 || h <= 0) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        left: rect.left,
                        top: rect.top,
                        width: w,
                        height: h,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.22),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
    );
    if (isLaptop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: scrollContent),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              setState(() {
                final w =
                    (_rightPanelsWidth - d.delta.dx)
                        .clamp(
                            BcvReadConstants.rightPanelsMinWidth, BcvReadConstants.rightPanelsMaxWidth)
                        .toDouble();
                _rightPanelsWidth = w;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(width: 6, color: Colors.transparent),
            ),
          ),
          SizedBox(
            width: _rightPanelsWidth,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBeige,
                border: Border(
                  left: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5)),
                ),
              ),
              child: SingleChildScrollView(
                child: _buildPanelsColumn(),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPanelsColumn(),
        Expanded(child: scrollContent),
      ],
    );
  }
}
