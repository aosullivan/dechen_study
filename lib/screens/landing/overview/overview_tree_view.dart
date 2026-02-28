import 'package:flutter/material.dart';

import 'overview_constants.dart';
import 'overview_node_card.dart';
import 'overview_tree_painter.dart';

/// Scrollable, zoomable tree of all sections with painted connector lines.
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
    this.onCardTap,
    this.scrollToPath,
    this.sectionVerseRanges,
    this.sectionHasReaderContent,
  });

  final List<({String path, String title, int depth})> flatSections;

  /// Which section paths are expanded (owned by parent).
  final Set<String> expandedPaths;

  /// Pre-computed verse range per section (e.g. "v1.1ab", "v1.2-1.3"). Optional.
  final Map<String, String>? sectionVerseRanges;
  final Map<String, bool>? sectionHasReaderContent;

  final String? selectedPath;

  /// Called when the book icon on a node is tapped (show verses).
  final ValueChanged<({String path, String title, int depth})> onBookTap;

  /// Called when the card body is tapped: select that card, update section stack, collapse others.
  final ValueChanged<({String path, String title, int depth})>? onCardTap;

  /// Called after a node is expanded or collapsed in the tree.
  final void Function(String path, bool expanded) onExpansionChanged;

  /// When set, the tree scrolls so this section path is near the top. (Ignored when using InteractiveViewer.)
  final String? scrollToPath;

  @override
  State<OverviewTreeView> createState() => _OverviewTreeViewState();
}

class _OverviewTreeViewState extends State<OverviewTreeView> {
  Set<String> _parentPathsCache = <String>{};
  List<({String path, String title, int depth})> _visibleSectionsCache =
      const [];
  bool _visibleSectionsDirty = true;
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
    final maxDepth = visibleSections.fold<int>(
      0,
      (currentMax, section) =>
          section.depth > currentMax ? section.depth : currentMax,
    );
    final totalWidth = OverviewConstants.leftPadding +
        (maxDepth + 1) * OverviewConstants.indentPerLevel +
        OverviewConstants.stubLength +
        OverviewConstants.nodeMaxWidth +
        24;

    return InteractiveViewer(
      constrained: false,
      minScale: 0.25,
      maxScale: 2.0,
      boundaryMargin: const EdgeInsets.all(100),
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          children: [
            // Layer 1: Connector lines.
            CustomPaint(
              size: Size(totalWidth, totalHeight),
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
                    hasChildren: parentPaths.contains(visibleSections[i].path),
                    isExpanded:
                        widget.expandedPaths.contains(visibleSections[i].path),
                    isSelected: visibleSections[i].path == widget.selectedPath,
                    verseRange:
                        widget.sectionVerseRanges?[visibleSections[i].path],
                    showBookIcon: widget.sectionHasReaderContent?[
                            visibleSections[i].path] ??
                        ((widget.sectionVerseRanges?[visibleSections[i].path] ??
                                '')
                            .isNotEmpty),
                    onTap: parentPaths.contains(visibleSections[i].path)
                        ? () => _toggleExpanded(visibleSections[i].path)
                        : () {},
                    onBookTap: () => widget.onBookTap(visibleSections[i]),
                    onCardTap: widget.onCardTap != null
                        ? () => widget.onCardTap!(visibleSections[i])
                        : null,
                  ),
                  if (i < visibleSections.length - 1)
                    const SizedBox(height: OverviewConstants.nodeGap),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
