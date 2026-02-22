import 'package:flutter/material.dart';

import 'overview_constants.dart';
import 'overview_node_card.dart';
import 'overview_tree_painter.dart';

/// Scrollable tree of all sections with painted connector lines.
/// Accepts a [TransformationController] so the parent can programmatically
/// scroll to a specific section.
class OverviewTreeView extends StatefulWidget {
  const OverviewTreeView({
    super.key,
    required this.flatSections,
    required this.selectedPath,
    required this.onNodeTap,
    this.scrollToPath,
  });

  final List<({String path, String title, int depth})> flatSections;
  final String? selectedPath;
  final ValueChanged<({String path, String title, int depth})> onNodeTap;

  /// When set, the tree scrolls so this section path is near the top.
  final String? scrollToPath;

  @override
  State<OverviewTreeView> createState() => _OverviewTreeViewState();
}

class _OverviewTreeViewState extends State<OverviewTreeView> {
  final _scrollController = ScrollController();
  final Set<String> _expandedPaths = <String>{};
  String? _lastScrolledTo;
  String _lastStructureSignature = '';

  @override
  void initState() {
    super.initState();
    _syncStructureAndExpansion();
  }

  @override
  void didUpdateWidget(OverviewTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStructureAndExpansion();
    if (widget.selectedPath != null &&
        widget.selectedPath != oldWidget.selectedPath) {
      final changed = _expandAncestors(widget.selectedPath!);
      if (changed) setState(() {});
    }
    if (widget.scrollToPath != null && widget.scrollToPath != _lastScrolledTo) {
      final changed = _expandAncestors(widget.scrollToPath!);
      if (changed) setState(() {});
      _lastScrolledTo = widget.scrollToPath;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
    }
  }

  void _syncStructureAndExpansion() {
    final signature = widget.flatSections.map((s) => s.path).join('|');
    if (signature == _lastStructureSignature) return;
    _lastStructureSignature = signature;
    _expandedPaths
      ..clear()
      ..addAll(
          widget.flatSections.where((s) => s.depth == 0).map((s) => s.path));
    if (widget.selectedPath != null) {
      _expandAncestors(widget.selectedPath!);
    }
    if (widget.scrollToPath != null) {
      _expandAncestors(widget.scrollToPath!);
    }
  }

  static String _parentPath(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(0, idx) : '';
  }

  bool _expandAncestors(String path) {
    var changed = false;
    var current = _parentPath(path);
    while (current.isNotEmpty) {
      if (_expandedPaths.add(current)) changed = true;
      current = _parentPath(current);
    }
    return changed;
  }

  bool _isVisible(String path) {
    var current = _parentPath(path);
    while (current.isNotEmpty) {
      if (!_expandedPaths.contains(current)) return false;
      current = _parentPath(current);
    }
    return true;
  }

  List<({String path, String title, int depth})> _visibleSections() {
    return widget.flatSections.where((s) => _isVisible(s.path)).toList();
  }

  Set<String> _parentPaths() {
    final out = <String>{};
    for (final section in widget.flatSections) {
      final parent = _parentPath(section.path);
      if (parent.isNotEmpty) out.add(parent);
    }
    return out;
  }

  void _toggleExpanded(String path) {
    setState(() {
      if (_expandedPaths.contains(path)) {
        _expandedPaths.removeWhere((p) => p == path || p.startsWith('$path.'));
      } else {
        _expandedPaths.add(path);
      }
    });
  }

  void _scrollToSection() {
    if (widget.scrollToPath == null) return;
    final visibleSections = _visibleSections();
    final idx =
        visibleSections.indexWhere((s) => s.path == widget.scrollToPath);
    if (idx < 0) return;
    final target = idx * OverviewConstants.nodeHeight;
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flatSections.isEmpty) {
      return const Center(child: Text('No sections loaded.'));
    }
    final visibleSections = _visibleSections();
    final parentPaths = _parentPaths();

    final totalHeight = visibleSections.length * OverviewConstants.nodeHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;

        return SingleChildScrollView(
          controller: _scrollController,
          child: SizedBox(
            width: viewportWidth,
            height: totalHeight,
            child: Stack(
              children: [
                // Layer 1: Connector lines.
                CustomPaint(
                  size: Size(viewportWidth, totalHeight),
                  painter: OverviewTreePainter(flatSections: visibleSections),
                ),
                // Layer 2: Node cards.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < visibleSections.length; i++)
                      OverviewNodeCard(
                        path: visibleSections[i].path,
                        title: visibleSections[i].title,
                        depth: visibleSections[i].depth,
                        hasChildren:
                            parentPaths.contains(visibleSections[i].path),
                        isExpanded:
                            _expandedPaths.contains(visibleSections[i].path),
                        isSelected:
                            visibleSections[i].path == widget.selectedPath,
                        onTap: () {
                          final hasChildren =
                              parentPaths.contains(visibleSections[i].path);
                          if (hasChildren) {
                            _toggleExpanded(visibleSections[i].path);
                          }
                          widget.onNodeTap(visibleSections[i]);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
