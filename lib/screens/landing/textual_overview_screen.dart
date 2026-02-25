import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bcv_read_screen.dart';
import '../../services/bcv_verse_service.dart';
import '../../services/usage_metrics_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';
import 'overview/overview_constants.dart';
import 'overview/overview_tree_view.dart';
import 'overview/overview_verse_panel.dart';

/// Full-screen hierarchical tree view of the entire text structure.
/// Cascading dropdown pickers at the top let you drill down level by level.
/// Tapping a section opens a side panel (desktop) or bottom sheet (mobile)
/// showing the verses for that section.
class TextualOverviewScreen extends StatefulWidget {
  const TextualOverviewScreen({super.key});

  @override
  State<TextualOverviewScreen> createState() => _TextualOverviewScreenState();
}

class _TextualOverviewScreenState extends State<TextualOverviewScreen>
    with WidgetsBindingObserver {
  static const _lastPathPrefsKey =
      'bodhicaryavatara_textual_structure_last_path';

  final _usageMetrics = UsageMetricsService.instance;
  bool _loading = true;
  List<({String path, String title, int depth})> _flatSections = [];
  DateTime? _screenDwellStartedAt;

  String? _selectedPath;
  String? _selectedTitle;

  /// Cascading picker selections: index i holds the chosen path at depth i.
  List<String> _pickerSelections = [];

  /// Set when a picker changes — the tree scrolls to this path.
  String? _scrollToPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screenDwellStartedAt = DateTime.now().toUtc();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackSurfaceDwell(nowUtc: DateTime.now().toUtc(), resetStart: true);
    unawaited(_usageMetrics.flush(all: true));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _trackSurfaceDwell(nowUtc: DateTime.now().toUtc(), resetStart: true);
      unawaited(_usageMetrics.flush(all: true));
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _screenDwellStartedAt ??= DateTime.now().toUtc();
    }
  }

  void _trackSurfaceDwell({
    required DateTime nowUtc,
    required bool resetStart,
  }) {
    final startedAt = _screenDwellStartedAt;
    if (startedAt == null) return;
    final durationMs = nowUtc.difference(startedAt).inMilliseconds;
    if (durationMs >= _usageMetrics.minDwellMs) {
      unawaited(_usageMetrics.trackSurfaceDwell(
        textId: 'bodhicaryavatara',
        mode: 'overview',
        durationMs: durationMs,
        sectionPath: _selectedPath,
        sectionTitle: _selectedTitle,
        properties: {
          'selected_depth': _selectedPath?.split('.').length,
        },
      ));
    }
    if (resetStart) _screenDwellStartedAt = null;
  }

  Future<void> _load() async {
    await Future.wait([
      BcvVerseService.instance.preload(),
      VerseHierarchyService.instance.preload(),
    ]);
    if (!mounted) return;
    final flatSections = VerseHierarchyService.instance.getFlatSectionsSync();
    final restoredPath = await _loadLastPath();
    if (!mounted) return;

    var restoredSelections = <String>[];
    String? restoredSelectedPath;
    String? restoredSelectedTitle;
    String? restoredScrollPath;

    if (restoredPath != null &&
        flatSections.any((s) => s.path == restoredPath)) {
      restoredSelections = _pickerSelectionsForPath(restoredPath);
      restoredScrollPath = restoredPath;
      final hasChildren = flatSections.any(
        (s) => s.path.startsWith('$restoredPath.'),
      );
      if (!hasChildren) {
        restoredSelectedPath = restoredPath;
        restoredSelectedTitle = flatSections
            .where((s) => s.path == restoredPath)
            .firstOrNull
            ?.title;
      }
    }

    setState(() {
      _flatSections = flatSections;
      _pickerSelections = restoredSelections;
      _selectedPath = restoredSelectedPath;
      _selectedTitle = restoredSelectedTitle;
      _scrollToPath = restoredScrollPath;
      _loading = false;
    });
  }

  Future<String?> _loadLastPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_lastPathPrefsKey)?.trim();
    if (path == null || path.isEmpty) return null;
    return path;
  }

  Future<void> _saveLastPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(_lastPathPrefsKey);
      return;
    }
    await prefs.setString(_lastPathPrefsKey, path.trim());
  }

  /// Returns children of [parentPath] (empty string = root-level sections).
  List<({String path, String title, int depth})> _childrenOf(
      String parentPath) {
    if (parentPath.isEmpty) {
      return _flatSections.where((s) => s.depth == 0).toList();
    }
    final parentDepth =
        _flatSections.where((s) => s.path == parentPath).firstOrNull?.depth;
    if (parentDepth == null) return [];
    final childDepth = parentDepth + 1;
    return _flatSections
        .where(
            (s) => s.depth == childDepth && s.path.startsWith('$parentPath.'))
        .toList();
  }

  static String _shortNum(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot + 1) : path;
  }

  static int _pathOrderValue(String path) {
    final first = path.split('.').first;
    return int.tryParse(first) ?? 999;
  }

  void _onPickerChanged(int depth, String? path) {
    unawaited(_usageMetrics.trackEvent(
      eventName: 'overview_picker_changed',
      textId: 'bodhicaryavatara',
      mode: 'overview',
      sectionPath: path,
      properties: {'depth': depth},
    ));
    String? restorablePath;
    setState(() {
      // Truncate selections beyond this depth.
      if (_pickerSelections.length > depth) {
        _pickerSelections = _pickerSelections.sublist(0, depth);
      }
      if (path != null) {
        _pickerSelections.add(path);
        _scrollToPath = path;
        // Deeper pickers (depth > 0) also select the section to show verses.
        if (depth > 0) {
          _selectedPath = path;
          _selectedTitle =
              _flatSections.where((s) => s.path == path).firstOrNull?.title;
        } else {
          // Top-level picker just filters, doesn't select.
          _selectedPath = null;
          _selectedTitle = null;
        }
        restorablePath = path;
      } else {
        // "All" picked — clear selection.
        _selectedPath = null;
        _selectedTitle = null;
        _scrollToPath =
            _pickerSelections.isNotEmpty ? _pickerSelections.last : null;
        restorablePath = _scrollToPath;
      }
    });
    unawaited(_saveLastPath(restorablePath));
  }

  /// Build picker selections from a section path.
  /// "4.3.2.1" -> ["4", "4.3", "4.3.2", "4.3.2.1"].
  /// Depth-0 nodes like "4" return ["4"].
  List<String> _pickerSelectionsForPath(String sectionPath) {
    final parts = sectionPath.split('.');
    final selections = <String>[];
    var prefix = '';
    for (final part in parts) {
      prefix = prefix.isEmpty ? part : '$prefix.$part';
      selections.add(prefix);
    }
    return selections;
  }

  /// Card body tap: highlight this card, collapse others, update section stack.
  void _onCardTap(({String path, String title, int depth}) section) {
    setState(() {
      _selectedPath = section.path;
      _selectedTitle = section.title;
      _pickerSelections = _pickerSelectionsForPath(section.path);
      _scrollToPath = section.path;
    });
    unawaited(_saveLastPath(section.path));
  }

  void _onBookTap(({String path, String title, int depth}) section) {
    unawaited(_usageMetrics.trackEvent(
      eventName: 'overview_book_tapped',
      textId: 'bodhicaryavatara',
      mode: 'overview',
      sectionPath: section.path,
      sectionTitle: section.title,
      properties: {
        'depth': section.depth,
      },
    ));

    final isDesktop =
        MediaQuery.sizeOf(context).width >= OverviewConstants.laptopBreakpoint;

    if (isDesktop) {
      setState(() {
        if (_selectedPath == section.path) {
          _selectedPath = null;
          _selectedTitle = null;
        } else {
          _selectedPath = section.path;
          _selectedTitle = section.title;
        }
      });
      unawaited(_saveLastPath(section.path));
    } else {
      setState(() {
        _selectedPath = section.path;
        _selectedTitle = section.title;
      });
      unawaited(_saveLastPath(section.path));
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.cardBeige,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => OverviewVersePanel(
            sectionPath: section.path,
            sectionTitle: section.title,
            scrollController: scrollController,
            onClose: () => Navigator.of(ctx).pop(),
            onOpenInReader: (params) {
              Navigator.of(ctx).pop();
              _openInReaderFromOverview(params);
            },
          ),
        ),
      ).whenComplete(() {
        if (mounted) setState(() => _selectedPath = null);
      });
    }
  }

  void _openInReaderFromOverview(ReaderOpenParams params) {
    unawaited(_usageMetrics.trackEvent(
      eventName: 'open_full_text_from_overview',
      textId: 'bodhicaryavatara',
      mode: 'overview',
      sectionPath: _selectedPath,
      sectionTitle: _selectedTitle,
    ));
    // Overview already preloaded in _load(); push immediately so reader opens fast.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BcvReadScreen(
          scrollToVerseIndex: params.scrollToVerseIndex,
          highlightSectionIndices: params.highlightSectionIndices,
          initialSegmentRef: params.initialSegmentRef,
        ),
      ),
    );
  }

  void _onExpansionChanged(String path, bool expanded) {
    setState(() {
      if (expanded) {
        _pickerSelections = _pickerSelectionsForPath(path);
      } else {
        final dotIdx = path.lastIndexOf('.');
        if (dotIdx > 0) {
          _pickerSelections =
              _pickerSelectionsForPath(path.substring(0, dotIdx));
        } else {
          // Root-level collapse — keep just the root.
          _pickerSelections = [path];
        }
      }
    });
    unawaited(_saveLastPath(
        _pickerSelections.isNotEmpty ? _pickerSelections.last : null));
  }

  /// Filtered flat sections: only the top-level picker (depth 0) filters.
  /// Deeper pickers just scroll, so the full subtree stays visible.
  List<({String path, String title, int depth})> get _filteredSections {
    if (_pickerSelections.isEmpty) return _flatSections;
    // Only filter by the first (top-level) selection.
    final root = _pickerSelections[0];
    final rootDepth =
        _flatSections.where((s) => s.path == root).firstOrNull?.depth ?? 0;
    return _flatSections
        .where((s) => s.path == root || s.path.startsWith('$root.'))
        .map((s) => (path: s.path, title: s.title, depth: s.depth - rootDepth))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.landingBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Textual Structure',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= OverviewConstants.laptopBreakpoint;
    final topSections = _childrenOf('')
      ..sort(
          (a, b) => _pathOrderValue(a.path).compareTo(_pathOrderValue(b.path)));

    if (_pickerSelections.isEmpty) {
      return Column(
        children: [
          _buildTopSectionPicker(topSections.take(5).toList()),
          Expanded(
            child: ColoredBox(
              color: AppColors.landingBackground,
              child: const Center(
                child: Text(
                  'Choose a top section to begin.',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 16,
                    color: AppColors.mutedBrown,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildPickers(),
        Expanded(
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: OverviewTreeView(
                        flatSections: _filteredSections,
                        expandedPaths: Set.from(_pickerSelections),
                        selectedPath: _selectedPath,
                        onBookTap: _onBookTap,
                        onCardTap: _onCardTap,
                        onExpansionChanged: _onExpansionChanged,
                        scrollToPath: _scrollToPath,
                        sectionVerseRanges:
                            VerseHierarchyService.instance.getSectionVerseRangeMapSync(),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: _selectedPath != null
                          ? OverviewConstants.versePanelWidth
                          : 0,
                      child: _selectedPath != null
                          ? OverviewVersePanel(
                              key: ValueKey(_selectedPath),
                              sectionPath: _selectedPath!,
                              sectionTitle: _selectedTitle ?? '',
                              onClose: () => setState(() {
                                _selectedPath = null;
                                _selectedTitle = null;
                              }),
                              onOpenInReader: _openInReaderFromOverview,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                )
              : OverviewTreeView(
                  flatSections: _filteredSections,
                  expandedPaths: Set.from(_pickerSelections),
                  selectedPath: _selectedPath,
                  onBookTap: _onBookTap,
                  onCardTap: _onCardTap,
                  onExpansionChanged: _onExpansionChanged,
                  scrollToPath: _scrollToPath,
                  sectionVerseRanges:
                      VerseHierarchyService.instance.getSectionVerseRangeMapSync(),
                ),
        ),
      ],
    );
  }

  Widget _buildTopSectionPicker(
      List<({String path, String title, int depth})> topSections) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              for (var i = 0; i < topSections.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onPickerChanged(0, topSections[i].path),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBeige,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${_shortNum(topSections[i].path)}.',
                              style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(height: 1.25) ??
                                  const TextStyle(
                                    fontFamily: 'Crimson Text',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                    height: 1.25,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              topSections[i].title,
                              softWrap: true,
                              style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(height: 1.25) ??
                                  const TextStyle(
                                    fontFamily: 'Crimson Text',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                    height: 1.25,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickers() {
    final pickers = <Widget>[];

    final rootChildren = _childrenOf('');
    if (rootChildren.isEmpty) return const SizedBox.shrink();

    pickers.add(_buildDropdownPicker(
      depth: 0,
      options: rootChildren,
      selectedPath: _pickerSelections.isNotEmpty ? _pickerSelections[0] : null,
    ));

    for (var i = 0; i < _pickerSelections.length; i++) {
      final children = _childrenOf(_pickerSelections[i]);
      if (children.isEmpty) break;
      pickers.add(_buildDropdownPicker(
        depth: i + 1,
        options: children,
        selectedPath:
            i + 1 < _pickerSelections.length ? _pickerSelections[i + 1] : null,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < pickers.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            pickers[i],
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownPicker({
    required int depth,
    required List<({String path, String title, int depth})> options,
    required String? selectedPath,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPath,
          hint: Text(
            depth == 0 ? 'Section' : 'Subsection',
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 13,
              color: AppColors.mutedBrown,
            ),
          ),
          isDense: true,
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 6),
            child:
                Icon(Icons.expand_more, size: 18, color: AppColors.mutedBrown),
          ),
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 13,
            color: AppColors.textDark,
          ),
          itemHeight: null,
          selectedItemBuilder: (context) {
            // The selected value should show the full title (no ellipsis).
            return [
              // "All" item:
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('All',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 13,
                      color: AppColors.mutedBrown,
                      fontStyle: FontStyle.italic,
                    )),
              ),
              // Each option:
              ...options.map((s) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_shortNum(s.path)}. ${s.title}',
                      softWrap: true,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  )),
            ];
          },
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text(
                'All',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 13,
                  color: AppColors.mutedBrown,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ...options.map((s) => DropdownMenuItem<String>(
                  value: s.path,
                  child: Text(
                    '${_shortNum(s.path)}. ${s.title}',
                    softWrap: true,
                  ),
                )),
          ],
          onChanged: (value) {
            if (value == null || value.isEmpty) {
              _onPickerChanged(depth, null);
            } else {
              _onPickerChanged(depth, value);
            }
          },
        ),
      ),
    );
  }
}
