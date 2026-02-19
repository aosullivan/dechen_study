import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'bcv/bcv_breadcrumb_bar.dart';
import 'bcv/bcv_chapters_panel.dart';
import 'bcv/bcv_collapsible_panel.dart';
import 'bcv/bcv_inline_commentary_panel.dart';
import 'bcv/bcv_mobile_nav_bar.dart';
import 'bcv/bcv_read_constants.dart';
import 'bcv/reader_nav_state.dart';
import 'bcv/bcv_section_overlay.dart';
import 'bcv/bcv_section_slider.dart';
import 'bcv/bcv_verse_text.dart';
import '../../services/bcv_verse_service.dart';
import '../../services/commentary_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';

/// Notifier for section-related state (breadcrumb, overlay, visible verse).
/// Allows panels and overlay to rebuild independently of the verse list.
class _SectionChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Read screen for Bodhicaryavatara: main area with full text, right-side panels for chapters, section overview, and breadcrumb.
/// Optional [scrollToVerseIndex] scrolls to the exact verse after first frame.
/// Optional [highlightSectionIndices] highlights all verses in that section (e.g. from Daily).
class BcvReadScreen extends StatefulWidget {
  const BcvReadScreen({
    super.key,
    this.scrollToVerseIndex,
    this.highlightSectionIndices,
    this.initialSegmentRef,
    this.title = 'Bodhicaryavatara',
    this.onSectionNavigateForTest,
    this.commentaryLoader,
  });

  final int? scrollToVerseIndex;

  /// When provided (e.g. from Daily "Full text"), these verses are highlighted as one section.
  final Set<int>? highlightSectionIndices;

  /// Optional split-verse ref (e.g. "1.14cd") for accurate initial section and overlay.
  /// Use when [scrollToVerseIndex] resolves from a segmented ref.
  final String? initialSegmentRef;
  final String title;

  /// Test-only: called when arrow-key navigation selects a section. Receives (sectionPath, firstVerseRef).
  /// Enables automated verification that key-down does not skip verses (e.g. 6.49 -> 6.50, not 6.52).
  final void Function(String sectionPath, String firstVerseRef)?
      onSectionNavigateForTest;

  /// Test seam: override commentary lookup.
  final Future<CommentaryEntry?> Function(String ref)? commentaryLoader;

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

  /// Min index in highlight set (computed on setState, for commentary button placement).
  int? _minHighlightIndex;

  /// Commentary for the currently selected verse group (loaded on tap); null if none or not loaded.
  CommentaryEntry? _commentaryEntryForSelected;

  final _commentaryService = CommentaryService.instance;
  final _hierarchyService = VerseHierarchyService.instance;

  final List<int> _chapterHeaderFlatIndices = <int>[];

  /// Verse index currently in view (for breadcrumb). Null until first visibility.
  int? _visibleVerseIndex;

  /// Section hierarchy for the visible verse. Each has 'section' and 'title'.
  List<Map<String, String>> _breadcrumbHierarchy = [];

  /// Verse indices belonging to the current section (for overlay measurement).
  Set<int>? _currentSectionVerseIndices = {};

  /// For split verses (e.g. 8.136ab / 8.136cd), tracks which segment ref is
  /// currently active so the overlay and scroll target the correct half.
  String? _currentSegmentRef;

  /// Animated section overlay: rect we're sliding from and to.
  Rect? _sectionOverlayRectFrom;
  Rect? _sectionOverlayRectTo;
  int _sectionOverlayAnimationId = 0;
  int _sectionOverlayMeasureRetries = 0;

  /// Cache: section path -> verse indices (avoids recomputing on same section).
  final Map<String, Set<int>> _sectionVerseIndicesCache = {};
  Timer? _visibilityDebounceTimer;

  /// Navigation state machine for debounce/generation/programmatic/cooldown.
  ReaderNavState _navState = const ReaderNavState.initial();

  /// True when the current highlight was set intentionally (e.g. from Daily Verse, or explicit
  /// navigation). Prevents visibility-driven processing from auto-clearing the highlight.
  /// Cleared only when the user explicitly navigates to a new section (chapter tap, arrow keys,
  /// breadcrumb tap).
  bool _intentionalHighlight = false;

  /// True while the user is actively scrolling (finger/wheel down). Gates visibility processing.
  bool _isUserScrolling = false;

  /// Per-verse visibility (0–1). We pick the verse with highest visibility = most centered in viewport.
  final Map<(int, String?), double> _verseVisibility = {};

  final Map<int, GlobalKey> _verseKeys = {};
  final Map<(int, int), GlobalKey> _verseSegmentKeys = {};
  final Map<int, List<({String ref, String sectionPath})>> _splitSegmentsCache =
      {};
  final GlobalKey _scrollContentKey = GlobalKey();
  final _sectionChangeNotifier = _SectionChangeNotifier();
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _sectionSliderScrollController = ScrollController();

  /// Incremented on each section slider scroll request. Stale retries check this.
  int _sectionSliderScrollRequestId = 0;

  bool _breadcrumbCollapsed = false;
  bool _sectionSliderCollapsed = false;
  bool _chaptersPanelCollapsed = false;
  bool _mobileNavCollapseInitialized = false;
  bool _deferredStartupWorkScheduled = false;

  final FocusNode _sectionOverviewFocusNode = FocusNode();

  double _rightPanelsWidth = 360;
  double _chaptersPanelHeight = 80;
  double _breadcrumbPanelHeight = 120;
  double _sectionPanelHeight = 220;

  /// Cached TextStyles — recomputed only when theme changes.
  TextStyle? _verseStyle;
  TextStyle? _chapterTitleStyle;

  bool get _isLaptopLayout =>
      MediaQuery.of(context).size.width >= BcvReadConstants.laptopBreakpoint;

  double get _readerLeftPadding => _isLaptopLayout ? 12.0 : 16.0;
  double get _readerRightPadding => _isLaptopLayout ? 20.0 : 16.0;
  double get _overlayLeftInset => _isLaptopLayout ? 12.0 : 8.0;
  double get _overlayRightInset => _isLaptopLayout ? 20.0 : 8.0;
  double get _verseHorizontalInset => _isLaptopLayout ? 28.0 : 18.0;
  double get _verseWrapIndent => _isLaptopLayout ? 24.0 : 8.0;

  Set<int> get _highlightSet => _highlightVerseIndices ?? const {};

  bool get _hasInitialHighlight =>
      widget.highlightSectionIndices != null &&
      widget.highlightSectionIndices!.isNotEmpty;

  /// Deep-link style open (e.g. Daily -> Full text): prioritize getting to verse first.
  bool get _isDeepLinkOpen =>
      widget.scrollToVerseIndex != null || _hasInitialHighlight;

  int get _syncGeneration => _navState.syncGeneration;

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

  /// Returns the initial split ref only when it resolves to [verseIndex].
  /// Prevents mismatching a stale ref to a different verse.
  String? _initialSegmentRefForVerseIndex(int verseIndex) {
    final ref = widget.initialSegmentRef;
    if (ref == null || ref.isEmpty) return null;
    final resolved = _verseService.getIndexForRefWithFallback(ref);
    if (resolved == verseIndex) return ref;
    return null;
  }

  void _applyNavEvent(ReaderNavEvent event, {DateTime? now}) {
    final ts = now ?? DateTime.now();
    final result = ReaderNavReducer.reduce(_navState, event, now: ts);
    _navState = result.state;
  }

  void _startProgrammaticNavigation() {
    _applyNavEvent(const ReaderProgrammaticStart());
  }

  void _markProgrammaticNavigationSettled() {
    _applyNavEvent(
      const ReaderProgrammaticSettled(Duration(milliseconds: 600)),
    );
  }

  bool _isVisibilitySuppressed() {
    _applyNavEvent(const ReaderNavTick());
    final now = DateTime.now();
    return _navState.isProgrammatic || _navState.isCooldownActive(now);
  }

  bool _tryAcceptArrowNav() {
    final now = DateTime.now();
    final result = ReaderNavReducer.reduce(
      _navState,
      const ReaderArrowAttempt(Duration(milliseconds: 200)),
      now: now,
    );
    _navState = result.state;
    return result.arrowAccepted;
  }

  @override
  void initState() {
    super.initState();
    if (_isDeepLinkOpen) {
      // Keep desktop startup light when opened from Daily/Verse deep links.
      _chaptersPanelCollapsed = true;
      _sectionSliderCollapsed = true;
      _breadcrumbCollapsed = true;
    }
    if (widget.scrollToVerseIndex != null || _hasInitialHighlight) {
      _scrollToVerseKey = GlobalKey();
    }
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context).textTheme;
    _verseStyle = theme.bodyLarge?.copyWith(
      fontFamily: 'Crimson Text',
      fontSize: 18,
      height: 1.5,
      color: AppColors.textDark,
    );
    _chapterTitleStyle = theme.displayMedium?.copyWith(
      fontFamily: 'Crimson Text',
      color: AppColors.textDark,
    );
  }

  @override
  void dispose() {
    _visibilityDebounceTimer?.cancel();
    _mainScrollController.dispose();
    _sectionSliderScrollController.dispose();
    _sectionOverviewFocusNode.dispose();
    _sectionChangeNotifier.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = null;
    setState(() {
      _loading = true;
      _error = null;
      _highlightVerseIndices = {};
      _minHighlightIndex = null;
      _sectionVerseIndicesCache.clear();
      _currentSectionVerseIndices = {};
      _currentSegmentRef = null;
      _sectionOverlayRectFrom = null;
      _sectionOverlayRectTo = null;
      _sectionOverlayMeasureRetries = 0;
      _verseVisibility.clear();
      _verseKeys.clear();
      _verseSegmentKeys.clear();
      _splitSegmentsCache.clear();
      _commentaryEntryForSelected = null;
      _navState = const ReaderNavState.initial();
      _intentionalHighlight = false;
      _sectionSliderScrollRequestId = 0;
      _chapterHeaderFlatIndices.clear();
      _deferredStartupWorkScheduled = false;
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
            _minHighlightIndex =
                _highlightVerseIndices!.reduce((a, b) => a < b ? a : b);
            _intentionalHighlight = true;
          } else if (widget.scrollToVerseIndex != null) {
            _highlightVerseIndices = {widget.scrollToVerseIndex!};
            _minHighlightIndex = widget.scrollToVerseIndex;
            _intentionalHighlight = true;
          }

          // Build flat indices for ListView.builder
          _chapterHeaderFlatIndices.clear();
          int flatIndex = 0;
          for (final c in chapters) {
            _chapterHeaderFlatIndices.add(flatIndex); // Header slot
            flatIndex += 1 + (c.endVerseIndex - c.startVerseIndex);
            _chapterKeys[c.number] = GlobalKey();
          }
        });
        if (widget.scrollToVerseIndex != null && _scrollToVerseKey != null) {
          // Activate programmatic-navigation guard so visibility callbacks
          // during and after the initial scroll animation cannot clear the
          // intentional highlight before the user has a chance to see it.
          _startProgrammaticNavigation();
          final initialAlignment = _initialDeepLinkScrollAlignment();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollToVerseIndex(
              widget.scrollToVerseIndex!,
              segmentRef: _initialSegmentRefForVerseIndex(
                widget.scrollToVerseIndex!,
              ),
              alignment: initialAlignment,
            );
            _clearProgrammaticNavigationAfterScrollSettles();
          });
        }
        if (_isDeepLinkOpen) {
          final initialIndex = _scrollTargetVerseIndex;
          if (initialIndex != null && initialIndex < _verses.length) {
            _visibleVerseIndex = initialIndex;
            _currentSectionVerseIndices = _highlightSet.isNotEmpty
                ? Set<int>.from(_highlightSet)
                : {initialIndex};
            _currentSegmentRef = _initialSegmentRefForVerseIndex(initialIndex);
            _sectionChangeNotifier.notify();
          }
          // Fallback in case scroll-settle callback doesn't fire.
          _scheduleDeferredStartupWork(
            delay: const Duration(milliseconds: 1200),
          );
        } else {
          if (widget.highlightSectionIndices != null &&
              _highlightSet.isNotEmpty) {
            _loadCommentaryForHighlightedSection();
          }
          _hierarchyService
              .getHierarchyForVerse('1.1'); // Preload hierarchy map
          _setInitialBreadcrumb();
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
    if (key?.currentContext == null) return;

    // Guard: treat chapter click as programmatic navigation so visibility
    // callbacks don't overwrite the expected focus.
    _startProgrammaticNavigation();
    final capturedGen = _syncGeneration;
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = null;
    _verseVisibility.clear(); // Discard stale visibility data

    // Clear any verse selection — user is navigating to a new chapter.
    _highlightVerseIndices = {};
    _intentionalHighlight = false;
    _minHighlightIndex = null;
    _commentaryEntryForSelected = null;

    // Update breadcrumb to the first section of the target chapter.
    final chapter = _chapters.firstWhere(
      (c) => c.number == chapterNumber,
      orElse: () => _chapters.first,
    );
    final firstVerseIndex = chapter.startVerseIndex;
    _visibleVerseIndex = firstVerseIndex;
    _hierarchyService
        .getHierarchyForVerseIndex(firstVerseIndex)
        .then((hierarchy) {
      if (!mounted || capturedGen != _syncGeneration) return;
      final sectionPath = hierarchy.isNotEmpty
          ? (hierarchy.last['section'] ?? hierarchy.last['path'] ?? '')
          : '';
      var indices = _verseIndicesForSection(sectionPath);
      if (indices.isEmpty && sectionPath.isNotEmpty) {
        indices = {firstVerseIndex};
      }
      _applySectionState(
        hierarchy: hierarchy,
        verseIndices: {...indices, firstVerseIndex},
        verseIndex: firstVerseIndex,
        supersedeGen: capturedGen,
      );
    });

    Scrollable.ensureVisible(key!.currentContext!,
        alignment: 0.0, duration: const Duration(milliseconds: 300));
    _clearProgrammaticNavigationAfterScrollSettles();
  }

  double _initialDeepLinkScrollAlignment() {
    final fromCardWithSectionHighlight =
        widget.scrollToVerseIndex != null && _hasInitialHighlight;
    if (fromCardWithSectionHighlight && !_isLaptopLayout) return 0.3;
    return 0.2;
  }

  void _scrollToVerseWidget({double alignment = 0.2}) {
    if (_scrollToVerseKey?.currentContext == null) return;
    Scrollable.ensureVisible(
      _scrollToVerseKey!.currentContext!,
      alignment: alignment,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Load commentary for the currently highlighted section (e.g. from Daily) so the Commentary button shows.
  Future<void> _loadCommentaryForHighlightedSection() async {
    if (_highlightSet.isEmpty) return;
    final firstIndex =
        _minHighlightIndex ?? _highlightSet.reduce((a, b) => a < b ? a : b);
    final baseRef = _verseService.getVerseRef(firstIndex);
    if (baseRef == null) return;
    final preferredRef = _initialSegmentRefForVerseIndex(firstIndex);
    CommentaryEntry? entry =
        await _getCommentaryForRef(preferredRef ?? baseRef);
    if (entry == null && preferredRef != null && preferredRef != baseRef) {
      entry = await _getCommentaryForRef(baseRef);
    }
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

  Future<void> _onVerseTap(int globalIndex, {String? segmentRef}) async {
    // Prefer the segment ref (e.g. "9.66ab") so split verses each get their own commentary.
    // Fall back to the base ref if the segment ref has no commentary of its own.
    final baseRef = _verseService.getVerseRef(globalIndex);
    if (baseRef == null) return;
    final lookupRef = segmentRef ?? baseRef;

    CommentaryEntry? entry = await _getCommentaryForRef(lookupRef);
    if (entry == null && lookupRef != baseRef) {
      entry = await _getCommentaryForRef(baseRef);
    }
    if (!mounted) return;

    // No commentary for this verse — do nothing.
    if (entry == null) return;

    setState(() {
      _commentaryEntryForSelected = entry;
    });
    _showCommentary();
  }

  Future<CommentaryEntry?> _getCommentaryForRef(String ref) {
    final loader = widget.commentaryLoader;
    if (loader != null) return loader(ref);
    return _commentaryService.getCommentaryForRef(ref);
  }

  /// Show commentary as a bottom sheet that gently springs up from the bottom.
  void _showCommentary() {
    final entry = _commentaryEntryForSelected;
    if (entry == null) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final initialSize = screenHeight > 900
        ? 0.92
        : screenHeight > 600
            ? 0.88
            : 0.8;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= BcvReadConstants.laptopBreakpoint;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.scaffoldBackground,
      barrierColor: Colors.black26,
      // On desktop, use most of the screen width; cap at 900 for readability.
      constraints: isDesktop
          ? BoxConstraints(maxWidth: screenWidth.clamp(0, 900).toDouble())
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 450),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: initialSize,
        minChildSize: 0.4,
        maxChildSize: 0.98,
        expand: false,
        builder: (_, scrollController) => BcvInlineCommentaryPanel(
          entry: entry,
          onClose: () => Navigator.of(ctx).pop(),
          forBottomSheet: true,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _scheduleDeferredStartupWork(
      {Duration delay = const Duration(milliseconds: 0)}) {
    if (!_isDeepLinkOpen || _deferredStartupWorkScheduled) return;
    _deferredStartupWorkScheduled = true;
    Future<void>.delayed(delay, () {
      if (!mounted) return;
      _setInitialBreadcrumb();
      if (widget.highlightSectionIndices != null && _highlightSet.isNotEmpty) {
        _loadCommentaryForHighlightedSection();
      }
      // Best-effort warm-up once initial jump is done.
      _hierarchyService.getHierarchyForVerse('1.1');
    });
  }

  void _setInitialBreadcrumb() {
    final initialIndex = _scrollTargetVerseIndex ?? 0;
    if (initialIndex >= _verses.length) return;
    final initialSegmentRef = _initialSegmentRefForVerseIndex(initialIndex);
    final hierarchyFuture = initialSegmentRef != null
        ? _hierarchyService.getHierarchyForVerse(initialSegmentRef)
        : _hierarchyService.getHierarchyForVerseIndex(initialIndex);
    hierarchyFuture.then((hierarchy) {
      if (!mounted) return;
      final sectionPath = hierarchy.isNotEmpty
          ? (hierarchy.last['section'] ?? hierarchy.last['path'] ?? '')
          : '';
      var indices = _verseIndicesForSection(sectionPath);
      if (indices.isEmpty && sectionPath.isNotEmpty) {
        indices = {initialIndex};
      }
      final indicesWithVisible = {...indices, initialIndex};
      // When opening from Daily "Full text", use the highlight set as the section
      // so the overlay box is drawn around those verses (not a hierarchy superset).
      final sectionIndices =
          _highlightSet.isNotEmpty ? _highlightSet : indicesWithVisible;
      _applySectionState(
        hierarchy: hierarchy,
        verseIndices: sectionIndices,
        verseIndex: initialIndex,
        segmentRef: initialSegmentRef,
      );
    });
  }

  /// Consecutive verse indices in current section but NOT in highlight.
  /// When the whole section is highlighted (e.g. from Daily), use full section.
  List<List<int>> _getSectionRuns() {
    final section = _currentSectionVerseIndices ?? {};
    final highlight = _highlightSet;
    var sectionOnly = section.difference(highlight).toList()..sort();
    if (sectionOnly.isEmpty && section.isNotEmpty) {
      sectionOnly = section.toList()..sort();
    }
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
        _sectionOverlayRectFrom = _sectionOverlayRectTo;
        _sectionOverlayRectTo = null;
        _sectionOverlayAnimationId++;
        _sectionChangeNotifier.notify();
      }
      return;
    }

    Rect? measured;
    final leftMargin = _overlayLeftInset;
    final rightMargin = _overlayRightInset;
    const verseBottomPadding = 20.0;
    const marginV = 6.0;
    for (final idx in run) {
      // For split verses, use the specific segment key when we know which
      // half is active (e.g. 8.136cd → use _verseSegmentKeys['N_1'], not ab).
      GlobalKey? key;
      final segRef = _currentSegmentRef;
      if (segRef != null) {
        final segIdx = _segmentIndexForRef(idx, segRef);
        if (segIdx > 0) {
          key = _verseSegmentKeys[(idx, segIdx)];
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
      measured =
          measured == null ? verseRect : measured.expandToInclude(verseRect);
    }
    if (measured == null) {
      if (_sectionOverlayMeasureRetries <
          BcvReadConstants.maxSectionOverlayMeasureRetries) {
        _sectionOverlayMeasureRetries++;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _measureAndUpdateSectionOverlay();
        });
      }
      return;
    }
    _sectionOverlayMeasureRetries = 0;

    final contentWidth = stackBox.size.width;
    final clamped = Rect.fromLTRB(
      leftMargin,
      measured.top - marginV,
      contentWidth - rightMargin,
      measured.bottom - verseBottomPadding + marginV,
    );

    final prevTo = _sectionOverlayRectTo;
    if (prevTo != null && _rectApproxEquals(prevTo, clamped)) return;

    _sectionOverlayRectFrom = prevTo ?? clamped;
    _sectionOverlayRectTo = clamped;
    _sectionOverlayAnimationId++;
    _sectionChangeNotifier.notify();
  }

  bool _rectApproxEquals(Rect a, Rect b, [double epsilon = 2]) {
    return (a.left - b.left).abs() < epsilon &&
        (a.top - b.top).abs() < epsilon &&
        (a.width - b.width).abs() < epsilon &&
        (a.height - b.height).abs() < epsilon;
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
      final i = _verseService.getIndexForRefWithFallback(ref);
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
    _breadcrumbHierarchy = hierarchy;
    _currentSectionVerseIndices = verseIndices;
    _currentSegmentRef = segmentRef;
    _visibleVerseIndex = verseIndex;
    _sectionChangeNotifier.notify();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureAndUpdateSectionOverlay();
      _scrollSectionSliderToCurrent();
    });
  }

  Future<void> _onBreadcrumbSectionTap(Map<String, String> item) async {
    final section = item['section'] ?? item['path'] ?? '';
    if (section.isEmpty) return;

    _startProgrammaticNavigation();
    _intentionalHighlight = false;
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = null;
    _verseVisibility.clear(); // Discard stale visibility data

    final hierarchy = _hierarchyService.getHierarchyForSectionSync(section);
    if (hierarchy.isNotEmpty) {
      final verseIndices = _verseIndicesForSection(section);
      // segmentRef resolved below after async load; use null here (early preview).
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
    final firstVerseRef = _hierarchyService
            .getFirstVerseForSectionInChapterSync(section, preferredChapter) ??
        _hierarchyService.getFirstVerseForSectionSync(section);
    if (firstVerseRef == null || firstVerseRef.isEmpty) return;
    final verseIndex = _verseService.getIndexForRefWithFallback(firstVerseRef);
    if (verseIndex == null) return;

    // Re-apply section state with the resolved verse so the chapter panel,
    // breadcrumb, and overlay all reflect the correct position.
    final resolvedHierarchy =
        _hierarchyService.getHierarchyForSectionSync(section);
    final resolvedIndices = _verseIndicesForSection(section);
    _applySectionState(
      hierarchy: resolvedHierarchy.isNotEmpty ? resolvedHierarchy : hierarchy,
      verseIndices: resolvedIndices.isNotEmpty ? resolvedIndices : {verseIndex},
      verseIndex: verseIndex,
      segmentRef: firstVerseRef,
    );
    _scrollToVerseIndex(verseIndex, segmentRef: firstVerseRef);
  }

  void _scrollToVerseIndex(int index,
      {String? segmentRef, double alignment = 0.2}) {
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = null;
    _startProgrammaticNavigation();
    _verseVisibility.clear(); // Discard stale visibility data
    // For split verses, prefer the specific segment key (e.g. cd half)
    // over the default verse key which always points to the ab half.
    GlobalKey? keyToUse;
    if (segmentRef != null) {
      final segIdx = _segmentIndexForRef(index, segmentRef);
      if (segIdx > 0) {
        keyToUse = _verseSegmentKeys[(index, segIdx)];
      }
    }
    keyToUse ??= _verseKeys[index];
    // Try scrolling using existing verse GlobalKey (avoids full rebuild)
    if (keyToUse?.currentContext != null) {
      Scrollable.ensureVisible(
        keyToUse!.currentContext!,
        alignment: alignment,
        duration: const Duration(milliseconds: 300),
      );
      _clearProgrammaticNavigationAfterScrollSettles();
      return;
    }
    // Fallback: attach temporary key via rebuild (for initial load / unmounted verses)
    _scrollToVerseIndexAfterTap = index;
    _scrollToVerseKey ??= GlobalKey();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToVerseWidget(alignment: alignment);
      setState(() => _scrollToVerseIndexAfterTap = null);
      _clearProgrammaticNavigationAfterScrollSettles();
    });
  }

  /// Clears programmatic-navigation mode only after the scroll animation finishes and
  /// visibility callbacks have settled. Prevents race where visibility updates
  /// overwrite the key-nav highlight.
  void _clearProgrammaticNavigationAfterScrollSettles() {
    void doClear() {
      if (!mounted) return;
      // Cancel any pending visibility timer
      _visibilityDebounceTimer?.cancel();
      _visibilityDebounceTimer = null;
      // Keep ignoring visibility-driven highlights briefly after settling.
      _markProgrammaticNavigationSettled();
      _measureAndUpdateSectionOverlay();
      _scheduleDeferredStartupWork();
    }

    final pos = _mainScrollController.hasClients
        ? _mainScrollController.position
        : null;
    if (pos != null && pos.isScrollingNotifier.value) {
      var listenerRemoved = false;
      VoidCallback? listener;
      listener = () {
        if (!mounted || pos.isScrollingNotifier.value) return;
        if (!listenerRemoved) {
          listenerRemoved = true;
          pos.isScrollingNotifier.removeListener(listener!);
        }
        // Brief buffer for visibility debounce to settle
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          doClear();
        });
      };
      pos.isScrollingNotifier.addListener(listener);
      // Fallback: clear after 800ms in case scroll never settles
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (!listenerRemoved) {
          listenerRemoved = true;
          pos.isScrollingNotifier.removeListener(listener!);
        }
        doClear();
      });
    } else {
      // No active scroll detected — wait for scroll animation (300ms) + buffer
      Future.delayed(const Duration(milliseconds: 400), doClear);
    }
  }

  void _onVerseVisibilityChanged(int verseIndex, double visibility,
      {String? segmentRef}) {
    if (_isVisibilitySuppressed()) return;
    final key = (verseIndex, segmentRef);
    if (visibility < 0.05) {
      _verseVisibility.remove(key);
      return;
    }
    _verseVisibility[key] = visibility;
    // While actively scrolling, record visibility but defer processing
    if (_isUserScrolling) return;
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      _visibilityDebounceTimer = null;
      _processVisibility();
    });
  }

  /// Core visibility processing: pick the best verse, look up hierarchy, apply section state.
  void _processVisibility() {
    if (!mounted || _verseVisibility.isEmpty || _isVisibilitySuppressed()) {
      return;
    }
    final capturedGen = _syncGeneration;
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
      // Only auto-clear a highlight if it was NOT set intentionally (e.g. from
      // Daily Verse or explicit navigation). Intentional highlights persist
      // until the user navigates away via chapter/section/arrow-key actions.
      if (_highlightSet.isNotEmpty &&
          !_highlightSet.contains(pickedIdx) &&
          !_intentionalHighlight) {
        setState(() {
          _highlightVerseIndices = {};
          _commentaryEntryForSelected = null;
        });
      }
      _applySectionState(
        hierarchy: hierarchy,
        verseIndices: indicesWithVisible,
        verseIndex: pickedIdx,
        segmentRef: pickedSegRef,
        supersedeGen: capturedGen,
      );
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
      return best.key;
    }
    final scrollOffset = pos.pixels;
    final viewportHeight = pos.viewportDimension;
    final viewportCenterY = scrollOffset + viewportHeight / 2;

    final stackContext = _scrollContentKey.currentContext;
    if (stackContext == null) return null;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return null;

    (int, String?)? bestKey;
    double bestDist = double.infinity;

    for (final entry in _verseVisibility.entries) {
      if (entry.value < 0.05) continue;
      final idx = entry.key.$1;
      final segRef = entry.key.$2;
      GlobalKey? gk = segRef != null
          ? _verseSegmentKeys[(idx, _segmentIndexForRef(idx, segRef))]
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
    return bestKey;
  }

  List<({String ref, String sectionPath})> _splitSegmentsForVerseIndex(
      int verseIndex) {
    final cached = _splitSegmentsCache[verseIndex];
    if (cached != null) return cached;
    final ref = _verseService.getVerseRef(verseIndex);
    if (ref == null || !BcvVerseService.baseVerseRefPattern.hasMatch(ref)) {
      return _splitSegmentsCache[verseIndex] =
          <({String ref, String sectionPath})>[];
    }
    final segments = _hierarchyService.getSplitVerseSegmentsSync(ref);
    _splitSegmentsCache[verseIndex] = segments;
    return segments;
  }

  int _segmentIndexForRef(int verseIndex, String segmentRef) {
    final segments = _splitSegmentsForVerseIndex(verseIndex);
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].ref == segmentRef) return i;
    }
    return 0;
  }

  void _scrollSectionSliderToCurrent() {
    if (_sectionSliderCollapsed) return;
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
    final viewportHeight = BcvReadConstants.sectionSliderLineHeight *
        BcvReadConstants.sectionSliderVisibleLines;
    final targetOffset = (idx * BcvReadConstants.sectionSliderLineHeight) -
        (viewportHeight / 2) +
        (BcvReadConstants.sectionSliderLineHeight / 2);
    final maxOffset = (flat.length * BcvReadConstants.sectionSliderLineHeight -
            viewportHeight)
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

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < BcvReadConstants.laptopBreakpoint;
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
        // On mobile, nav is the segment bar below; no duplicate icons in app bar.
        actions: isMobile
            ? []
            : [
                IconButton(
                  icon: Icon(
                    _chaptersPanelCollapsed
                        ? Icons.menu_book
                        : Icons.menu_book_outlined,
                    color: AppColors.textDark,
                  ),
                  tooltip:
                      _chaptersPanelCollapsed ? 'Show Chapter' : 'Hide Chapter',
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
                      ? 'Show Breadcrumb'
                      : 'Hide Breadcrumb',
                  onPressed: () => setState(
                      () => _breadcrumbCollapsed = !_breadcrumbCollapsed),
                ),
                IconButton(
                  icon: Icon(
                    _sectionSliderCollapsed ? Icons.list : Icons.list_alt,
                    color: AppColors.textDark,
                  ),
                  tooltip:
                      _sectionSliderCollapsed ? 'Show Section' : 'Hide Section',
                  onPressed: () => setState(
                      () => _sectionSliderCollapsed = !_sectionSliderCollapsed),
                ),
              ],
      ),
      body: _buildBody(),
    );
  }

  /// Handler for reader pane: arrow keys for section nav, Enter/Space to show commentary.
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
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final visibleIdx = _visibleVerseIndex ?? _scrollTargetVerseIndex;
      if (visibleIdx != null) {
        _onVerseTap(visibleIdx, segmentRef: _currentSegmentRef);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Handler for section overview: uses leaf-based nav (same as reader) so arrow keys
  /// always move through sections in verse order without skipping.
  KeyEventResult _handleSectionOverviewKeyEvent(
      FocusNode node, KeyEvent event) {
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

  /// Slim bar on mobile: section name + prev/next (replaces arrow keys).
  Widget _buildMobileSectionNavBar() {
    final sectionTitle = _breadcrumbHierarchy.isNotEmpty
        ? (_breadcrumbHierarchy.last['title'] ?? '').trim()
        : '';
    final centerLabel = sectionTitle.isNotEmpty ? sectionTitle : 'Section';
    return Material(
      color: AppColors.cardBeige,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                tooltip: 'Previous section',
                onPressed: () =>
                    _debouncedArrowNav(() => _scrollToAdjacentSection(-1)),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  centerLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.textDark,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: 'Next section',
                onPressed: () =>
                    _debouncedArrowNav(() => _scrollToAdjacentSection(1)),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Run [fn] only if enough time has passed since last arrow nav (debounce 200ms).
  void _debouncedArrowNav(void Function() fn) {
    if (!_tryAcceptArrowNav()) return;
    fn();
  }

  /// Navigate to previous (direction -1) or next (direction 1) section.
  /// Reader pane: uses leaf sections only so each key down moves exactly one
  /// "lowest level" section forward (no jumps to parents, no skipping).
  void _scrollToAdjacentSection(int direction) {
    final leafOrdered = _hierarchyService.getLeafSectionsByVerseOrderSync();
    if (leafOrdered.isEmpty) return;

    final visibleIdx = _visibleVerseIndex ?? _scrollTargetVerseIndex;
    final verseRef =
        visibleIdx != null ? _verseService.getVerseRef(visibleIdx) : null;
    final currentPath = _currentSectionPath;

    var currentIdx = -1;
    if (currentPath.isNotEmpty) {
      currentIdx = leafOrdered.indexWhere((s) => s.path == currentPath);
    }
    if (currentIdx < 0 && verseRef != null && verseRef.isNotEmpty) {
      final hierarchy = _hierarchyService.getHierarchyForVerseSync(verseRef);
      if (hierarchy.isNotEmpty) {
        final leafPath =
            hierarchy.last['section'] ?? hierarchy.last['path'] ?? '';
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
        useFullRefOrder: true,
      );
    } else {
      return;
    }

    if (newIdx < 0 || newIdx >= leafOrdered.length) return;
    final section = leafOrdered[newIdx];

    // Fully synchronous path — no async gaps that let the next key press race.
    _startProgrammaticNavigation();
    _intentionalHighlight = false;
    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = null;
    _verseVisibility.clear(); // Discard stale visibility data

    final hierarchy =
        _hierarchyService.getHierarchyForSectionSync(section.path);
    final verseIndices = _verseIndicesForSection(section.path);

    final preferredChapter = _currentChapterNumber;
    final firstVerseRef =
        _hierarchyService.getFirstVerseForSectionInChapterSync(
                section.path, preferredChapter) ??
            _hierarchyService.getFirstVerseForSectionSync(section.path);
    widget.onSectionNavigateForTest?.call(section.path, firstVerseRef ?? '');
    if (firstVerseRef == null || firstVerseRef.isEmpty) return;
    final verseIndex = _verseService.getIndexForRefWithFallback(firstVerseRef);
    if (verseIndex == null) return;

    _applySectionState(
      hierarchy: hierarchy,
      verseIndices: verseIndices.isNotEmpty ? verseIndices : {verseIndex},
      verseIndex: verseIndex,
      segmentRef: firstVerseRef,
    );
    _scrollToVerseIndex(verseIndex, segmentRef: firstVerseRef);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
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

  void _mobileToggleChapter() {
    setState(() {
      final wasExpanded = !_chaptersPanelCollapsed;
      _chaptersPanelCollapsed = !_chaptersPanelCollapsed;
      if (!_chaptersPanelCollapsed) {
        _sectionSliderCollapsed = true;
        _breadcrumbCollapsed = true;
      }
      if (wasExpanded) _cooldownAfterPanelClose();
    });
  }

  void _mobileToggleSection() {
    setState(() {
      final wasExpanded = !_sectionSliderCollapsed;
      _sectionSliderCollapsed = !_sectionSliderCollapsed;
      if (!_sectionSliderCollapsed) {
        _chaptersPanelCollapsed = true;
        _breadcrumbCollapsed = true;
      }
      if (wasExpanded) _cooldownAfterPanelClose();
    });
  }

  void _mobileToggleBreadcrumb() {
    setState(() {
      final wasExpanded = !_breadcrumbCollapsed;
      _breadcrumbCollapsed = !_breadcrumbCollapsed;
      if (!_breadcrumbCollapsed) {
        _chaptersPanelCollapsed = true;
        _sectionSliderCollapsed = true;
      }
      if (wasExpanded) _cooldownAfterPanelClose();
    });
  }

  /// After closing a nav pane, ignore visibility-driven section updates briefly
  /// so the highlighted verse doesn't jump when the viewport resizes.
  void _cooldownAfterPanelClose() {
    _applyNavEvent(
      const ReaderProgrammaticSettled(Duration(milliseconds: 500)),
    );
  }

  Widget _buildPanelsColumn() {
    final breadcrumbSubtitle = _breadcrumbHierarchy.isNotEmpty
        ? (_breadcrumbHierarchy.last['title'] ?? '').trim()
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
    final isMobile =
        MediaQuery.of(context).size.width < BcvReadConstants.laptopBreakpoint;

    // Mobile: single segment bar + one expanded pane. Pane height is content-sized
    // (breadcrumb) or capped with scroll (chapter/section) so the reader fills the rest.
    if (isMobile) {
      final maxH = BcvReadConstants.mobilePanelMaxHeight;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BcvMobileNavBar(
            chaptersCollapsed: _chaptersPanelCollapsed,
            sectionCollapsed: _sectionSliderCollapsed,
            breadcrumbCollapsed: _breadcrumbCollapsed,
            onToggleChapter: _mobileToggleChapter,
            onToggleSection: _mobileToggleSection,
            onToggleBreadcrumb: _mobileToggleBreadcrumb,
          ),
          if (!_chaptersPanelCollapsed)
            SizedBox(
              height: maxH,
              child: SingleChildScrollView(
                child: _buildChaptersPanel(height: maxH),
              ),
            ),
          if (!_sectionSliderCollapsed)
            SizedBox(
              height: maxH,
              child: SingleChildScrollView(
                child: _buildSectionSlider(
                  height: maxH,
                  collapsed: false,
                ),
              ),
            ),
          // Breadcrumb: size to content (no fixed height) so reader fills space below.
          if (!_breadcrumbCollapsed)
            BcvBreadcrumbBar(
              hierarchy: _breadcrumbHierarchy,
              sectionNumberForDisplay: _sectionNumberForDisplay,
              onSectionTap: _onBreadcrumbSectionTap,
            ),
        ],
      );
    }

    // Laptop: full collapsible sections with resize handles.
    final sectionSubtitle = breadcrumbSubtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BcvNavSection(
          collapsed: _chaptersPanelCollapsed,
          label: 'Chapter',
          subtitle: chaptersSubtitle,
          expandedChild: _buildChaptersPanel(height: _chaptersPanelHeight),
          onExpand: () => setState(() => _chaptersPanelCollapsed = false),
          onCollapse: () => setState(() => _chaptersPanelCollapsed = true),
        ),
        BcvVerticalResizeHandle(onDragDelta: (dy) {
          setState(() {
            if (_chaptersPanelHeight + dy >= BcvReadConstants.panelMinHeight &&
                _sectionPanelHeight - dy >= BcvReadConstants.panelMinHeight) {
              _chaptersPanelHeight += dy;
              _sectionPanelHeight -= dy;
            }
          });
        }),
        BcvNavSection(
          collapsed: _sectionSliderCollapsed,
          label: 'Section',
          subtitle: sectionSubtitle,
          expandedChild: _buildSectionSlider(
            height: _sectionPanelHeight,
            collapsed: _sectionSliderCollapsed,
          ),
          onExpand: () => setState(() => _sectionSliderCollapsed = false),
          onCollapse: () => setState(() => _sectionSliderCollapsed = true),
          contentHeight: _sectionPanelHeight,
        ),
        BcvVerticalResizeHandle(onDragDelta: (dy) {
          setState(() {
            if (_sectionPanelHeight + dy >= BcvReadConstants.panelMinHeight &&
                _breadcrumbPanelHeight - dy >=
                    BcvReadConstants.panelMinHeight) {
              _sectionPanelHeight += dy;
              _breadcrumbPanelHeight -= dy;
            }
          });
        }),
        BcvNavSection(
          collapsed: _breadcrumbCollapsed,
          label: 'Breadcrumb',
          subtitle: sectionSubtitle,
          expandedChild: BcvBreadcrumbBar(
            hierarchy: _breadcrumbHierarchy,
            sectionNumberForDisplay: _sectionNumberForDisplay,
            onSectionTap: _onBreadcrumbSectionTap,
          ),
          onExpand: () => setState(() => _breadcrumbCollapsed = false),
          onCollapse: () => setState(() => _breadcrumbCollapsed = true),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    final isLaptop = _isLaptopLayout;
    final scrollContent = Focus(
      autofocus: true,
      onKeyEvent: _handleReaderKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // No onTap here: verse InkWells must receive taps to open commentary.
        // On mobile, use the section nav bar for prev/next section.
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              _isUserScrolling = true;
            } else if (notification is ScrollEndNotification) {
              _isUserScrolling = false;
              // Process deferred visibility now that scroll settled — but only
              // if we're not in programmatic navigation or its cooldown period.
              if (_verseVisibility.isNotEmpty && !_isVisibilitySuppressed()) {
                _visibilityDebounceTimer?.cancel();
                _visibilityDebounceTimer =
                    Timer(const Duration(milliseconds: 100), () {
                  _visibilityDebounceTimer = null;
                  _processVisibility();
                });
              }
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _mainScrollController,
            padding: EdgeInsets.fromLTRB(
              _readerLeftPadding,
              20,
              _readerRightPadding,
              20,
            ),
            child: Stack(
              key: _scrollContentKey,
              clipBehavior: Clip.none,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final overlayHorizontalMargin =
                        _overlayLeftInset + _overlayRightInset;
                    final contentMaxWidth =
                        (constraints.maxWidth - overlayHorizontalMargin)
                            .clamp(0.0, double.infinity);
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                  style: _chapterTitleStyle,
                                ),
                                const SizedBox(height: 24),
                                ...() {
                                  final verseStyle = _verseStyle;

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
                                            .sublist(
                                                lineRange[0], lineRange[1] + 1)
                                            .join('\n')
                                        : text;
                                    final isSplitSegment =
                                        segmentIndex != null &&
                                            segmentIndex > 0;
                                    if (!isSplitSegment) {
                                      _verseKeys[idx] ??= GlobalKey();
                                    } else {
                                      _verseSegmentKeys[(idx, segmentIndex)] ??=
                                          GlobalKey();
                                    }
                                    final isTargetVerse =
                                        _scrollTargetVerseIndex != null &&
                                            _scrollTargetVerseIndex == idx &&
                                            _scrollToVerseKey != null &&
                                            (segmentIndex ?? 0) == 0;
                                    final effectiveStyle = verseStyle ??
                                        Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontFamily: 'Crimson Text',
                                              fontSize: 18,
                                              height: 1.5,
                                              color: AppColors.textDark,
                                            );
                                    final ref = _verseService.getVerseRef(idx);
                                    Widget refWidget = const SizedBox.shrink();
                                    if (ref != null &&
                                        (segmentIndex == null ||
                                            segmentIndex == 0)) {
                                      refWidget = Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 8),
                                        child: Text(
                                          'Verse $ref',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontFamily: 'Lora',
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      );
                                    }
                                    final inner = Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          _verseHorizontalInset,
                                          0,
                                          _verseHorizontalInset,
                                          0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          refWidget,
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 0, 0, 20),
                                            child: BcvVerseText(
                                              text: displayText,
                                              style: effectiveStyle,
                                              wrapIndent: _verseWrapIndent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    Widget w = inner;
                                    if (isTargetVerse) {
                                      w = KeyedSubtree(
                                          key: _scrollToVerseKey, child: w);
                                    }
                                    w = SizedBox(
                                      width: double.infinity,
                                      child: InkWell(
                                        onTap: () => _onVerseTap(idx,
                                            segmentRef: segmentRef),
                                        hoverColor: Colors.transparent,
                                        child: w,
                                      ),
                                    );
                                    final subtreeKey = isSplitSegment
                                        ? _verseSegmentKeys[(idx, segmentIndex)]
                                        : _verseKeys[idx];
                                    final key = subtreeKey ??
                                        ValueKey(
                                            'verse_${idx}_seg_$segmentIndex');
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
                                    if (lineCount < 2 || segmentIndex > 1) {
                                      return null;
                                    }
                                    final half = lineCount ~/ 2;
                                    if (segmentIndex == 0) {
                                      return [0, half - 1];
                                    }
                                    return [half, lineCount - 1];
                                  }

                                  final children = <Widget>[];
                                  final highlightRuns = _getHighlightRuns();
                                  final highlightRunByStart = {
                                    for (final run in highlightRuns)
                                      run.first: run,
                                  };
                                  final highlightIndices = _highlightSet;

                                  for (final entry
                                      in verseTexts.asMap().entries) {
                                    final localIndex = entry.key;
                                    final verse = entry.value;
                                    final globalIndex =
                                        ch.startVerseIndex + localIndex;

                                    if (highlightIndices
                                            .contains(globalIndex) &&
                                        !highlightRunByStart
                                            .containsKey(globalIndex)) {
                                      continue;
                                    }

                                    final highlightRun =
                                        highlightRunByStart[globalIndex];
                                    if (highlightRun != null &&
                                        highlightRun.first == globalIndex) {
                                      // Render highlighted verses without the light box; overlay draws the border.
                                      for (final idx in highlightRun) {
                                        final text = idx < _verses.length
                                            ? _verses[idx]
                                            : '';
                                        final segments =
                                            _splitSegmentsForVerseIndex(idx);
                                        final isSplit = segments.length >= 2;
                                        if (isSplit) {
                                          final lines = text.split('\n');
                                          if (lines.length >= 2) {
                                            for (var i = 0;
                                                i < segments.length;
                                                i++) {
                                              final range = lineRangeForSegment(
                                                  i, lines.length);
                                              if (range != null) {
                                                children.add(
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: buildVerseContent(
                                                      idx,
                                                      text,
                                                      lineRange: range,
                                                      segmentIndex: i,
                                                      segmentRef:
                                                          segments[i].ref,
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
                                                    idx, text),
                                              ),
                                            );
                                          }
                                        } else {
                                          children.add(
                                            SizedBox(
                                              width: double.infinity,
                                              child:
                                                  buildVerseContent(idx, text),
                                            ),
                                          );
                                        }
                                      }
                                      continue;
                                    }

                                    // Section highlight is drawn via animated overlay.
                                    // For split verses, render as two blocks so overlay can highlight each segment.
                                    final segments =
                                        _splitSegmentsForVerseIndex(
                                            globalIndex);
                                    final isSplit = segments.length >= 2;
                                    if (isSplit) {
                                      final lines = verse.split('\n');
                                      if (lines.length >= 2) {
                                        for (var i = 0;
                                            i < segments.length;
                                            i++) {
                                          final range = lineRangeForSegment(
                                              i, lines.length);
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
                    );
                  },
                ),
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: _sectionChangeNotifier,
                    builder: (_, __) {
                      if (_sectionOverlayRectTo == null) {
                        return const SizedBox.shrink();
                      }
                      return BcvSectionOverlay(
                        animationId: _sectionOverlayAnimationId,
                        rectFrom: _sectionOverlayRectFrom,
                        rectTo: _sectionOverlayRectTo,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
                final w = (_rightPanelsWidth - d.delta.dx)
                    .clamp(BcvReadConstants.rightPanelsMinWidth,
                        BcvReadConstants.rightPanelsMaxWidth)
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
                child: ListenableBuilder(
                  listenable: _sectionChangeNotifier,
                  builder: (_, __) => _buildPanelsColumn(),
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Mobile: nav (segment bar + optional pane) is content-sized; reader fills the rest.
    if (!_mobileNavCollapseInitialized) {
      _mobileNavCollapseInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _chaptersPanelCollapsed = true;
            _sectionSliderCollapsed = true;
            _breadcrumbCollapsed = true;
          });
        }
      });
    }
    // Constrain panels height so Column never overflows (e.g. in tests or small viewports).
    return LayoutBuilder(
      builder: (context, constraints) {
        const minReaderHeight = 100.0;
        final maxPanelsHeight = (constraints.maxHeight -
                minReaderHeight -
                BcvReadConstants.mobileNavBarHeight)
            .clamp(0.0, double.infinity);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPanelsHeight),
              child: SingleChildScrollView(
                child: ListenableBuilder(
                  listenable: _sectionChangeNotifier,
                  builder: (_, __) => _buildPanelsColumn(),
                ),
              ),
            ),
            Expanded(child: scrollContent),
            ListenableBuilder(
              listenable: _sectionChangeNotifier,
              builder: (_, __) => _buildMobileSectionNavBar(),
            ),
          ],
        );
      },
    );
  }
}
