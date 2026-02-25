import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'overview_constants.dart';
import 'overview_node_card.dart';
import 'overview_tree_painter.dart';

/// Scrollable tree of all sections with painted connector lines.
/// Expansion is controlled by the parent via [expandedPaths]; the tree only
/// reports expand/collapse via [onExpansionChanged].
class OverviewTreeView extends StatefulWidget {
  const OverviewTreeView({
    super.key,
    required this.flatSections,
    required this.expandedPaths,
    required this.selectedPath,
    required this.onBookTap,
    required this.onExpansionChanged,
    this.scrollToPath,
  });

  final List<({String path, String title, int depth})> flatSections;

  /// Which section paths are expanded (owned by parent).
  final Set<String> expandedPaths;

  final String? selectedPath;

  /// Called when the book icon on a node is tapped (show verses).
  final ValueChanged<({String path, String title, int depth})> onBookTap;

  /// Called after a node is expanded or collapsed in the tree.
  final void Function(String path, bool expanded) onExpansionChanged;

  /// When set, the tree scrolls so this section path is near the top.
  final String? scrollToPath;

  @override
  State<OverviewTreeView> createState() => _OverviewTreeViewState();
}

class _OverviewTreeViewState extends State<OverviewTreeView> {
  final _scrollController = ScrollController();
  final _horizontalScrollController = ScrollController();
  Set<String> _parentPathsCache = <String>{};
  List<({String path, String title, int depth})> _visibleSectionsCache =
      const [];
  bool _visibleSectionsDirty = true;
  String? _lastScrolledTo;
  String _lastStructureSignature = '';

  @override
  void initState() {
    super.initState();
    _syncStructure();
  }

  @override
  void didUpdateWidget(OverviewTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStructure();
    if (!identical(widget.expandedPaths, oldWidget.expandedPaths)) {
      _visibleSectionsDirty = true;
    }
    if (widget.scrollToPath != null &&
        widget.scrollToPath != _lastScrolledTo) {
      _lastScrolledTo = widget.scrollToPath;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
    }
  }

  void _syncStructure() {
    final signature = widget.flatSections.map((s) => s.path).join('|');
    if (signature == _lastStructureSignature) return;
    _lastStructureSignature = signature;
    _parentPathsCache = <String>{};
    for (final section in widget.flatSections) {
      final parent = _parentPath(section.path);
      if (parent.isNotEmpty) _parentPathsCache.add(parent);
    }
    _visibleSectionsDirty = true;
  }

  static String _parentPath(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(0, idx) : '';
  }

  /// Visibility: section is visible if all its ancestors are in widget.expandedPaths.
  bool _isVisible(String path) {
    var current = _parentPath(path);
    while (current.isNotEmpty) {
      if (!widget.expandedPaths.contains(current)) return false;
      current = _parentPath(current);
    }
    return true;
  }

  void _ensureVisibleSections() {
    if (!_visibleSectionsDirty) return;
    _visibleSectionsCache =
        widget.flatSections.where((s) => _isVisible(s.path)).toList();
    _visibleSectionsDirty = false;
  }

  List<({String path, String title, int depth})> get _visibleSections {
    _ensureVisibleSections();
    return _visibleSectionsCache;
  }

  /// User tapped expand/collapse; tell parent so it updates picker and rebuilds us.
  void _toggleExpanded(String path) {
    final expanded = !widget.expandedPaths.contains(path);
    widget.onExpansionChanged(path, expanded);
  }

  void _scrollToSection() {
    if (widget.scrollToPath == null) return;
    final visibleSections = _visibleSections;
    final idx =
        visibleSections.indexWhere((s) => s.path == widget.scrollToPath);
    if (idx < 0) return;
    final itemHeight = OverviewConstants.nodeHeight + OverviewConstants.nodeGap;
    final target = idx * itemHeight;
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  double _maxRequiredTreeWidth(
    BuildContext context,
    List<({String path, String title, int depth})> visibleSections,
    Set<String> parentPaths,
  ) {
    final textDirection = Directionality.of(context);
    var requiredWidth = 0.0;
    for (final section in visibleSections) {
      final shortNumber = _shortNumber(section.path);
      final titleSpan = TextSpan(
        children: [
          TextSpan(
            text: '$shortNumber. ',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: OverviewConstants.fontSizeForDepth(section.depth) - 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: section.title,
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: OverviewConstants.fontSizeForDepth(section.depth),
              fontWeight: OverviewConstants.fontWeightForDepth(section.depth),
            ),
          ),
        ],
      );
      final labelPainter = TextPainter(
        text: titleSpan,
        textDirection: textDirection,
        maxLines: 1,
      )..layout();
      final indent = section.depth * OverviewConstants.indentPerLevel +
          OverviewConstants.leftPadding +
          (section.depth > 0 ? OverviewConstants.stubLength : 0);
      final hasChildren = parentPaths.contains(section.path);
      final expandIconSlot = hasChildren ? 40.0 : 20.0; // 40 = tap target for chevron
      final horizontalPadding = 20.0;
      final gapAfterIcon = 4.0;
      final bookIconWidth = 26.0; // SizedBox(6) + Padding(4) + Icon(16)
      final rowWidth = indent +
          horizontalPadding +
          expandIconSlot +
          gapAfterIcon +
          labelPainter.width +
          bookIconWidth;
      if (rowWidth > requiredWidth) requiredWidth = rowWidth;
    }
    return requiredWidth;
  }

  static String _shortNumber(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot + 1) : path;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flatSections.isEmpty) {
      return const Center(child: Text('No sections loaded.'));
    }
    final visibleSections = _visibleSections;
    final parentPaths = _parentPathsCache;

    final totalHeight = visibleSections.length * OverviewConstants.nodeHeight +
        (visibleSections.length > 1
            ? (visibleSections.length - 1) * OverviewConstants.nodeGap
            : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final maxDepth = visibleSections.fold<int>(
          0,
          (currentMax, section) =>
              section.depth > currentMax ? section.depth : currentMax,
        );
        final maxIndent = maxDepth * OverviewConstants.indentPerLevel +
            OverviewConstants.leftPadding +
            (maxDepth > 0 ? OverviewConstants.stubLength : 0);
        // Keep row width stable as depth grows: indentation should add
        // scrollable width, not shrink the visible card area.
        final baseCardWidth = viewportWidth - OverviewConstants.leftPadding;
        final baseContentWidth = maxIndent + baseCardWidth;
        final textContentWidth =
            _maxRequiredTreeWidth(context, visibleSections, parentPaths);
        final contentWidth = textContentWidth > baseContentWidth
            ? textContentWidth
            : baseContentWidth;
        final treeWidth =
            contentWidth > viewportWidth ? contentWidth : viewportWidth;

        return SingleChildScrollView(
          controller: _scrollController,
          dragStartBehavior: DragStartBehavior.start,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: treeWidth,
              height: totalHeight,
              child: Stack(
                children: [
                  // Layer 1: Connector lines.
                  CustomPaint(
                    size: Size(treeWidth, totalHeight),
                    painter: OverviewTreePainter(flatSections: visibleSections),
                  ),
                  // Layer 2: Node cards.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < visibleSections.length; i++) ...[
                        OverviewNodeCard(
                          path: visibleSections[i].path,
                          title: visibleSections[i].title,
                          depth: visibleSections[i].depth,
                          hasChildren:
                              parentPaths.contains(visibleSections[i].path),
                          isExpanded:
                              widget.expandedPaths.contains(visibleSections[i].path),
                          isSelected:
                              visibleSections[i].path == widget.selectedPath,
                          onTap: parentPaths.contains(visibleSections[i].path)
                              ? () =>
                                  _toggleExpanded(visibleSections[i].path)
                              : () {},
                          onBookTap: () =>
                              widget.onBookTap(visibleSections[i]),
                        ),
                        if (i < visibleSections.length - 1)
                          const SizedBox(height: OverviewConstants.nodeGap),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
