import 'package:flutter/material.dart';

/// Renders verse text so that when a logical line wraps, continuation lines
/// are indented (keeps the "4 lines" look). Logical lines are split by '\n'.
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
        // ListView can pass unbounded maxWidth; use a finite width so wrap+indent works.
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 400.0;
        if (maxWidth <= 0) return Text(text, style: style);

        final children = <Widget>[];
        for (var i = 0; i < logicalLines.length; i++) {
          final line = logicalLines[i];
          if (line.isEmpty) {
            children.add(SizedBox(height: style.height != null ? style.fontSize! * style.height! : 18));
            continue;
          }
          // Every logical line starts flush left. Only when a line wraps does the continuation get indented.
          children.add(_IndentedLine(
            line: line,
            style: style,
            maxWidth: maxWidth,
            indent: wrapIndent,
          ));
          if (i < logicalLines.length - 1) {
            final lineGap = (style.fontSize ?? 18) *
                ((style.height ?? 1.5) - 1.0).clamp(0.0, 20.0);
            children.add(SizedBox(height: lineGap));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      },
    );
  }
}

class _IndentedLine extends StatelessWidget {
  const _IndentedLine({
    required this.line,
    required this.style,
    required this.maxWidth,
    required this.indent,
  });

  final String line;
  final TextStyle style;
  final double maxWidth;
  final double indent;

  @override
  Widget build(BuildContext context) {
    if (line.isEmpty) return Text(line, style: style);
    if (maxWidth <= 0 || !maxWidth.isFinite) return Text(line, style: style);

    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final lineHeight = painter.preferredLineHeight;
    if (lineHeight <= 0) {
      painter.dispose();
      return Text(line, style: style);
    }

    // Does this line wrap? (more than one visual line)
    final wraps = painter.height > lineHeight + 1;
    if (!wraps) {
      painter.dispose();
      return Text(line, style: style);
    }

    // Build list of (start, end) character offsets for each visual line.
    final segmentEnds = <int>[];
    var y = lineHeight / 2;
    while (y < painter.height && segmentEnds.length < 100) {
      final position = painter.getPositionForOffset(Offset(maxWidth - 1, y));
      var end = position.offset.clamp(0, line.length);
      // Prefer word boundary so we don't split mid-word.
      if (end < line.length && end > 0 && line[end] != ' ' && line[end] != '\n') {
        final lastSpace = line.lastIndexOf(' ', end);
        if (lastSpace > (segmentEnds.isEmpty ? 0 : segmentEnds.last)) {
          end = lastSpace + 1;
        }
      }
      segmentEnds.add(end);
      if (end >= line.length) break;
      y += lineHeight;
    }
    painter.dispose();

    if (segmentEnds.isEmpty) return Text(line, style: style);

    // Merge any duplicate end offsets (same line) and ensure strictly increasing.
    final ends = <int>[];
    var last = 0;
    for (final e in segmentEnds) {
      if (e > last) {
        ends.add(e);
        last = e;
      }
      if (last >= line.length) break;
    }
    if (ends.isEmpty) return Text(line, style: style);

    var start = 0;
    final children = <Widget>[];
    for (var i = 0; i < ends.length; i++) {
      final end = ends[i];
      final segment = line.substring(start, end).trimRight();
      if (segment.isNotEmpty) {
        final isFirst = i == 0;
        final textWidget = Text(segment, style: style);
        if (isFirst) {
          children.add(textWidget);
        } else {
          children.add(
            Padding(
              padding: EdgeInsets.only(left: indent),
              child: SizedBox(
                width: (maxWidth - indent).clamp(0.0, double.infinity),
                child: textWidget,
              ),
            ),
          );
        }
      }
      start = end;
      if (start >= line.length) break;
      if (i < ends.length - 1) {
        children.add(SizedBox(height: (style.fontSize ?? 18) * ((style.height ?? 1.5) - 1.0).clamp(0.0, 20.0)));
      }
    }

    if (children.isEmpty) return Text(line, style: style);
    if (children.length == 1) return children[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
