import 'package:flutter/material.dart';

import 'overview_constants.dart';
import 'overview_node_card.dart';
import 'overview_tree_painter.dart';

/// Scrollable, zoomable tree of all sections with painted connector lines.
class OverviewTreeView extends StatelessWidget {
  const OverviewTreeView({
    super.key,
    required this.flatSections,
    required this.selectedPath,
    required this.onNodeTap,
  });

  final List<({String path, String title, int depth})> flatSections;
  final String? selectedPath;
  final ValueChanged<({String path, String title, int depth})> onNodeTap;

  @override
  Widget build(BuildContext context) {
    if (flatSections.isEmpty) {
      return const Center(child: Text('No sections loaded.'));
    }

    final totalHeight = flatSections.length * OverviewConstants.nodeHeight;
    // Compute content width: max indent + node max width + some padding.
    final maxDepth =
        flatSections.fold<int>(0, (m, s) => s.depth > m ? s.depth : m);
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
              painter: OverviewTreePainter(flatSections: flatSections),
            ),
            // Layer 2: Node cards.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < flatSections.length; i++)
                  OverviewNodeCard(
                    path: flatSections[i].path,
                    title: flatSections[i].title,
                    depth: flatSections[i].depth,
                    isSelected: flatSections[i].path == selectedPath,
                    onTap: () => onNodeTap(flatSections[i]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
