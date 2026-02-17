import 'package:flutter/material.dart';

/// Layout and styling constants for the Textual Overview screen.
abstract final class OverviewConstants {
  OverviewConstants._();

  static const double nodeHeight = 40.0;
  static const double indentPerLevel = 28.0;
  static const double leftPadding = 20.0;
  static const double stubLength = 16.0;
  static const double nodeMaxWidth = 320.0;
  static const double connectorLineWidth = 1.0;
  static const double versePanelWidth = 360.0;
  static const double laptopBreakpoint = 900.0;

  /// Background colors for nodes at different depths (warm beige tones).
  static Color depthColor(int depth) {
    const colors = [
      Color(0xFFF0E8DC), // depth 0
      Color(0xFFF3ECE2), // depth 1
      Color(0xFFF5F0E8), // depth 2
      Color(0xFFF8F4EE), // depth 3–4
      Color(0xFFFAF8F4), // depth 5+
    ];
    return colors[depth.clamp(0, colors.length - 1)];
  }

  static double fontSizeForDepth(int depth) {
    if (depth <= 1) return 14.0;
    if (depth <= 4) return 13.0;
    return 12.0;
  }

  static FontWeight fontWeightForDepth(int depth) {
    if (depth <= 1) return FontWeight.w600;
    if (depth <= 4) return FontWeight.w500;
    return FontWeight.normal;
  }
}
