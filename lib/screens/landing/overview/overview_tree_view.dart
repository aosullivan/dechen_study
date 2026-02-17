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
  String? _lastScrolledTo;

  @override
  void didUpdateWidget(OverviewTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollToPath != null &&
        widget.scrollToPath != _lastScrolledTo) {
      _lastScrolledTo = widget.scrollToPath;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
    }
  }

  void _scrollToSection() {
    if (widget.scrollToPath == null) return;
    final idx = widget.flatSections
        .indexWhere((s) => s.path == widget.scrollToPath);
    if (idx < 0) return;
    final target = idx * OverviewConstants.nodeHeight;
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

    final totalHeight =
        widget.flatSections.length * OverviewConstants.nodeHeight;

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
                  painter: OverviewTreePainter(
                      flatSections: widget.flatSections),
                ),
                // Layer 2: Node cards.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < widget.flatSections.length; i++)
                      OverviewNodeCard(
                        path: widget.flatSections[i].path,
                        title: widget.flatSections[i].title,
                        depth: widget.flatSections[i].depth,
                        isSelected:
                            widget.flatSections[i].path == widget.selectedPath,
                        onTap: () => widget.onNodeTap(widget.flatSections[i]),
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
