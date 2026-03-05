import 'package:flutter/material.dart';

/// Testable line-breaking for verse text. Used by [BcvVerseText] and by tests.
class VerseLineBreaker {
  VerseLineBreaker._();

  /// Splits [line] into visual-line segments at [maxWidth] using [style].
  /// Returns segments and the [lineHeight] used for layout (for computing total height).
  /// First segment is flush; rest are continuation lines (to be indented).
  static ({List<String> segments, double lineHeight}) getVisualLineSegments(
      String line, TextStyle style, double maxWidth,
      {double continuationIndent = 0.0}) {
    final fallbackLineHeight = (style.fontSize ?? 14) * (style.height ?? 1.5);
    if (line.isEmpty || maxWidth <= 0 || !maxWidth.isFinite) {
      return (
        segments: line.isEmpty ? <String>[] : [line],
        lineHeight: fallbackLineHeight
      );
    }

    final probePainter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final lineHeight = probePainter.preferredLineHeight > 0
        ? probePainter.preferredLineHeight
        : fallbackLineHeight;
    probePainter.dispose();

    final continuationWidth = (maxWidth - continuationIndent).clamp(
      1.0,
      double.infinity,
    );

    final segments = <String>[];
    var remaining = line;
    var isFirst = true;

    while (remaining.isNotEmpty) {
      final width = isFirst ? maxWidth : continuationWidth;
      final split = _lineBreakOffsetForWidth(remaining, style, width);
      final end = split.clamp(1, remaining.length);
      final segment = remaining.substring(0, end).trimRight();
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
      if (end >= remaining.length) break;
      remaining = remaining.substring(end).trimLeft();
      isFirst = false;
    }

    return (
      segments: segments.isEmpty ? [line.trimRight()] : segments,
      lineHeight: lineHeight,
    );
  }

  static int _lineBreakOffsetForWidth(
    String line,
    TextStyle style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final metrics = painter.computeLineMetrics();
    if (metrics.length <= 1) {
      painter.dispose();
      return line.length;
    }
    final probeY =
        (painter.preferredLineHeight * 0.5).clamp(0.0, painter.height);
    final breakOffset = painter
        .getPositionForOffset(Offset(maxWidth, probeY))
        .offset
        .clamp(0, line.length)
        .toInt();
    painter.dispose();
    if (breakOffset <= 0) return 1;
    if (breakOffset >= line.length) return line.length;

    if (line[breakOffset - 1] != ' ' && line[breakOffset] != ' ') {
      final lastWhitespace = line.lastIndexOf(' ', breakOffset - 1);
      if (lastWhitespace >= 0) {
        return lastWhitespace + 1;
      }
    }
    return breakOffset;
  }
}

/// Renders verse text so that when a logical line wraps, continuation lines
/// are indented by [wrapIndent]. Logical lines are split by '\n'.
/// Uses a single CustomPaint pass so every continuation line gets exactly
/// the same left offset (no stacking).
class BcvVerseText extends StatelessWidget {
  const BcvVerseText({
    super.key,
    required this.text,
    required this.style,
    this.wrapIndent = 24.0,
  });

  final String text;
  final TextStyle style;
  final double wrapIndent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalLines = text.split('\n');
        final maxWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 400.0;
        if (maxWidth <= 0) return Text(text, style: style);

        final lineGap = (style.fontSize ?? 18) *
            ((style.height ?? 1.5) - 1.0).clamp(0.0, 20.0);
        final children = <Widget>[];

        for (var i = 0; i < logicalLines.length; i++) {
          final line = logicalLines[i];
          if (line.isEmpty) {
            children.add(SizedBox(
                height: style.height != null
                    ? style.fontSize! * style.height!
                    : 18));
            continue;
          }
          children.add(_PaintedIndentedLine(
            line: line,
            style: style,
            maxWidth: maxWidth,
            indent: wrapIndent,
            lineGap: lineGap,
          ));
          if (i < logicalLines.length - 1) {
            children.add(SizedBox(height: lineGap));
          }
        }

        return Semantics(
          label: text,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
    );
  }
}

/// One logical line: layout with TextPainter, split into visual-line segments,
/// then paint each segment at an explicit (x, y). First line at x=0, rest at x=indent.
class _PaintedIndentedLine extends StatelessWidget {
  const _PaintedIndentedLine({
    required this.line,
    required this.style,
    required this.maxWidth,
    required this.indent,
    required this.lineGap,
  });

  final String line;
  final TextStyle style;
  final double maxWidth;
  final double indent;
  final double lineGap;

  @override
  Widget build(BuildContext context) {
    if (line.isEmpty) return Text(line, style: style);
    if (maxWidth <= 0 || !maxWidth.isFinite) {
      return Text(line, style: style);
    }

    final result = VerseLineBreaker.getVisualLineSegments(
      line,
      style,
      maxWidth,
      continuationIndent: indent,
    );
    final segments = result.segments;

    if (segments.length <= 1) {
      return SizedBox(
        width: maxWidth,
        child: Text(line, style: style),
      );
    }

    var totalHeight = 0.0;
    for (var i = 0; i < segments.length; i++) {
      final isFirst = i == 0;
      final width =
          isFirst ? maxWidth : (maxWidth - indent).clamp(1.0, double.infinity);
      final painter = TextPainter(
        text: TextSpan(text: segments[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      totalHeight += painter.height;
      painter.dispose();
      if (i < segments.length - 1) totalHeight += lineGap;
    }

    return SizedBox(
      width: maxWidth,
      height: totalHeight,
      child: CustomPaint(
        size: Size(maxWidth, totalHeight),
        painter: _VerseLinePainter(
          segments: segments,
          style: style,
          maxWidth: maxWidth,
          indent: indent,
          lineGap: lineGap,
        ),
      ),
    );
  }
}

/// Paints each segment at (0, y) for the first line and (indent, y) for the rest.
/// Same x offset for all continuations — no stacking.
class _VerseLinePainter extends CustomPainter {
  _VerseLinePainter({
    required this.segments,
    required this.style,
    required this.maxWidth,
    required this.indent,
    required this.lineGap,
  });

  final List<String> segments;
  final TextStyle style;
  final double maxWidth;
  final double indent;
  final double lineGap;

  @override
  void paint(Canvas canvas, Size size) {
    var y = 0.0;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isFirst = i == 0;
      final width =
          isFirst ? maxWidth : (maxWidth - indent).clamp(1.0, double.infinity);
      final x = isFirst ? 0.0 : indent;

      final painter = TextPainter(
        text: TextSpan(text: segment, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);

      painter.paint(canvas, Offset(x, y));
      final paintedHeight = painter.height;
      painter.dispose();

      y += paintedHeight;
      if (i < segments.length - 1) y += lineGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerseLinePainter oldDelegate) {
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i] != segments[i]) return true;
    }
    return oldDelegate.maxWidth != maxWidth ||
        oldDelegate.indent != indent ||
        oldDelegate.lineGap != lineGap ||
        oldDelegate.style != style;
  }
}
