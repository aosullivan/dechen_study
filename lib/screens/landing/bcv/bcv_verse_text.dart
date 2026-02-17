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
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0) return Text(text, style: style);

        final children = <Widget>[];
        for (var i = 0; i < logicalLines.length; i++) {
          final line = logicalLines[i];
          if (line.isEmpty) {
            children.add(SizedBox(height: style.height != null ? style.fontSize! * style.height! : 18));
            continue;
          }
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
    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 20,
    );
    painter.layout(maxWidth: maxWidth);
    final lineHeight = painter.preferredLineHeight;
    if (lineHeight <= 0) return Text(line, style: style);
    final lineCount = (painter.height / lineHeight).ceil().clamp(1, 20);
    if (lineCount <= 1) return Text(line, style: style);

    final spans = <Widget>[];
    var start = 0;
    for (var i = 0; i < lineCount; i++) {
      final endOffset = painter.getPositionForOffset(
        Offset(maxWidth, lineHeight * (i + 1) - 1),
      ).offset;
      final end = endOffset.clamp(0, line.length);
      final segment = i > 0
          ? line.substring(start, end).trimLeft()
          : line.substring(start, end);
      if (segment.isNotEmpty) {
        spans.add(
          Padding(
            padding: i > 0 ? EdgeInsets.only(left: indent) : EdgeInsets.zero,
            child: Text(segment, style: style),
          ),
        );
      }
      start = end;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: spans,
    );
  }
}
