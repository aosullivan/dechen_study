import 'package:flutter/material.dart';

/// Testable line-breaking for verse text. Used by [BcvVerseText] and by tests.
class VerseLineBreaker {
  VerseLineBreaker._();

  /// Splits [line] into visual-line segments at [maxWidth] using [style].
  /// Returns segments and the [lineHeight] used for layout (for computing total height).
  /// First segment is flush; rest are continuation lines (to be indented).
  static ({List<String> segments, double lineHeight}) getVisualLineSegments(
    String line,
    TextStyle style,
    double maxWidth,
  ) {
    if (line.isEmpty || maxWidth <= 0 || !maxWidth.isFinite) {
      final h = (style.fontSize ?? 14) * (style.height ?? 1.5);
      return (segments: line.isEmpty ? <String>[] : [line], lineHeight: h);
    }

    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final lineHeight = painter.preferredLineHeight;
    if (lineHeight <= 0) {
      painter.dispose();
      return (segments: [line], lineHeight: (style.fontSize ?? 14) * (style.height ?? 1.5));
    }

    final numVisualLines = (painter.height / lineHeight).round().clamp(1, 200);
    if (numVisualLines <= 1) {
      painter.dispose();
      return (segments: [line], lineHeight: lineHeight);
    }

    final ends = <int>[];
    for (var i = 0; i < numVisualLines; i++) {
      final yNextLine = (i + 1) * lineHeight;
      if (yNextLine >= painter.height) {
        ends.add(line.length);
        break;
      }
      final position = painter.getPositionForOffset(Offset(0, yNextLine));
      var end = position.offset.clamp(0, line.length);
      if (end < line.length && end > 0 && line[end] != ' ' && line[end] != '\n') {
        final segmentStart = ends.isEmpty ? 0 : ends.last;
        final lastSpace = line.lastIndexOf(' ', end);
        if (lastSpace >= segmentStart) end = lastSpace + 1;
      }
      if (ends.isNotEmpty && end <= ends.last) {
        end = (ends.last + 1).clamp(0, line.length);
      }
      ends.add(end);
      if (end >= line.length) break;
    }
    painter.dispose();

    if (ends.isEmpty) return (segments: [line], lineHeight: lineHeight);

    final segments = <String>[];
    var start = 0;
    for (final end in ends) {
      final seg = line.substring(start, end).trimRight();
      if (seg.isNotEmpty) segments.add(seg);
      start = end;
      if (start >= line.length) break;
    }

    return (
      segments: segments.isEmpty ? [line] : segments,
      lineHeight: lineHeight,
    );
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
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
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

    final result = VerseLineBreaker.getVisualLineSegments(line, style, maxWidth);
    final segments = result.segments;
    final lineHeight = result.lineHeight;

    if (segments.length <= 1) {
      return SizedBox(
        width: maxWidth,
        child: Text(line, style: style),
      );
    }

    final totalHeight =
        segments.length * lineHeight + (segments.length - 1) * lineGap;

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
          lineHeight: lineHeight,
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
    required this.lineHeight,
    required this.lineGap,
  });

  final List<String> segments;
  final TextStyle style;
  final double maxWidth;
  final double indent;
  final double lineHeight;
  final double lineGap;

  @override
  void paint(Canvas canvas, Size size) {
    var y = 0.0;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isFirst = i == 0;
      final width = isFirst ? maxWidth : (maxWidth - indent).clamp(1.0, double.infinity);
      final x = isFirst ? 0.0 : indent;

      final painter = TextPainter(
        text: TextSpan(text: segment, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);

      painter.paint(canvas, Offset(x, y));
      painter.dispose();

      y += lineHeight + lineGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerseLinePainter oldDelegate) {
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i] != segments[i]) return true;
    }
    return oldDelegate.maxWidth != maxWidth || oldDelegate.indent != indent;
  }
}
