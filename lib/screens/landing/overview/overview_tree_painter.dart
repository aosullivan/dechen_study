import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import 'overview_constants.dart';

/// Paints vertical rails and horizontal stubs that connect sibling/parent nodes.
///
/// For each parent section, a vertical line spans from its first child's
/// y-center to its last child's y-center. Each child gets a horizontal stub
/// from the rail to the node card.
class OverviewTreePainter extends CustomPainter {
  OverviewTreePainter({
    required this.flatSections,
  });

  final List<({String path, String title, int depth})> flatSections;

  @override
  void paint(Canvas canvas, Size size) {
    if (flatSections.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = OverviewConstants.connectorLineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Pre-compute parent ranges: parentPath -> (firstChildFlatIndex, lastChildFlatIndex).
    final parentRanges = <String, (int, int)>{};
    final childDepths = <String, int>{};

    for (var i = 0; i < flatSections.length; i++) {
      final path = flatSections[i].path;
      final depth = flatSections[i].depth;
      final dotIdx = path.lastIndexOf('.');
      final parentPath = dotIdx >= 0 ? path.substring(0, dotIdx) : '';

      final existing = parentRanges[parentPath];
      if (existing == null) {
        parentRanges[parentPath] = (i, i);
        childDepths[parentPath] = depth;
      } else {
        parentRanges[parentPath] = (existing.$1, i);
      }
    }

    const nodeH = OverviewConstants.nodeHeight;
    const leftPad = OverviewConstants.leftPadding;
    const indent = OverviewConstants.indentPerLevel;
    const stub = OverviewConstants.stubLength;

    for (final entry in parentRanges.entries) {
      final (first, last) = entry.value;
      if (first == last) continue; // single child, no rail needed

      final depth = childDepths[entry.key] ?? 0;
      final railX = leftPad + depth * indent;
      final topY = first * nodeH + nodeH / 2;
      final bottomY = last * nodeH + nodeH / 2;

      // Vertical rail.
      canvas.drawLine(Offset(railX, topY), Offset(railX, bottomY), paint);
    }

    // Horizontal stubs for every non-root node.
    for (var i = 0; i < flatSections.length; i++) {
      final depth = flatSections[i].depth;
      if (depth == 0) continue; // root nodes have no parent rail

      final railX = leftPad + depth * indent;
      final y = i * nodeH + nodeH / 2;

      canvas.drawLine(Offset(railX, y), Offset(railX + stub, y), paint);
    }
  }

  @override
  bool shouldRepaint(OverviewTreePainter oldDelegate) =>
      !identical(flatSections, oldDelegate.flatSections);
}
