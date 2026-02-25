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
          // First logical line flush left; subsequent lines indented (same as wrapped continuation).
          final isFirstLine = i == 0;
          final lineWidth = isFirstLine ? maxWidth : maxWidth - wrapIndent;
          final lineIndent = isFirstLine ? wrapIndent : 0.0; // Only first line's wrap gets extra indent
          final lineWidget = _IndentedLine(
            line: line,
            style: style,
            maxWidth: lineWidth,
            indent: lineIndent,
          );
          children.add(
            isFirstLine
                ? lineWidget
                : Padding(
                    padding: EdgeInsets.only(left: wrapIndent),
                    child: lineWidget,
                  ),
          );
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
    )..layout(maxWidth: maxWidth);
    final lineHeight = painter.preferredLineHeight;
    if (lineHeight <= 0 || painter.height <= lineHeight) {
      painter.dispose();
      return Text(line, style: style);
    }

    // Find where the first visual line ends.
    var firstLineEnd = painter
        .getPositionForOffset(Offset(maxWidth, lineHeight - 1))
        .offset
        .clamp(0, line.length);
    painter.dispose();

    if (firstLineEnd >= line.length) return Text(line, style: style);

    // Break at a word boundary so we don't split mid-word and lose a word when trimming.
    // Only back up when we'd split a word (current position not after a space).
    if (firstLineEnd > 0 &&
        firstLineEnd < line.length &&
        line[firstLineEnd - 1] != ' ' &&
        line[firstLineEnd - 1] != '\n') {
      final lastSpace = line.lastIndexOf(' ', firstLineEnd);
      if (lastSpace > 0) {
        firstLineEnd = lastSpace + 1; // include space in first line
      }
    }

    final firstLineText = line.substring(0, firstLineEnd).trimRight();
    final restText = line.substring(firstLineEnd).trimLeft();

    if (restText.isEmpty) return Text(line, style: style);

    // Render first line at full width, continuation lines indented.
    // Constrain continuation width so it wraps at the same effective width and
    // all wrapped continuation lines stay at the same indent.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(firstLineText, style: style),
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: SizedBox(
            width: maxWidth - indent,
            child: Text(restText, style: style),
          ),
        ),
      ],
    );
  }
}
