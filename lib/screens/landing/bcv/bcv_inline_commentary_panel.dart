import 'package:flutter/material.dart';

import '../../../services/commentary_service.dart';
import '../../../utils/app_theme.dart';
import 'bcv_verse_text.dart';

/// Commentary panel: sticky header with section title + scrollable mixed verse/prose content.
/// The verses and prose flow in the order they appear in the source — no split between
/// "verse block" at top and "commentary" below.
class BcvInlineCommentaryPanel extends StatelessWidget {
  const BcvInlineCommentaryPanel({
    super.key,
    required this.entry,
    required this.onClose,
    this.forBottomSheet = false,
    /// When set (from DraggableScrollableSheet), the panel manages its own scroll
    /// so the header stays pinned while the content scrolls.
    this.scrollController,
  });

  final CommentaryEntry entry;
  final VoidCallback onClose;
  final bool forBottomSheet;
  final ScrollController? scrollController;

  // ── Section title extraction ──────────────────────────────────────────────

  /// Returns the section title from the first structural heading in [text]
  /// (e.g. "4. Establishing vastness" → "Establishing vastness"), or null.
  /// Only looks at lines before the first verse ref or `>>>` line.
  static String? _extractSectionTitle(String text) {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      // Stop once we reach verse content
      if (RegExp(r'^\d+\.\d+').hasMatch(t)) break;
      if (t.startsWith('>>>')) break;
      // Match structural heading "N. Title text"
      final m = RegExp(r'^\d+\.\s+(.+)$').firstMatch(t);
      if (m != null) return m.group(1)!.trim();
    }
    return null;
  }

  // ── Segment parsing ───────────────────────────────────────────────────────

  static List<_Seg> _parseSegments(String text) {
    final segs = <_Seg>[];
    // Once we hit the first >>> line, we're past the structural preamble.
    // All numbered outline lines (headings, sub-headings, topic lists) before
    // that point are stripped — they belong to the outline shown in the banner,
    // not to the readable content.
    bool seenVerse = false;

    for (final raw in text.split('\n')) {
      final t = raw.trim();

      if (t.isEmpty) {
        if (segs.isNotEmpty && segs.last is! _BlankSeg) segs.add(const _BlankSeg());
        continue;
      }

      // Verse ref line (e.g. "1.32") — keep even in preamble
      if (RegExp(r'^\d+\.\d+\s*$').hasMatch(t)) {
        segs.add(_RefSeg(t));
        continue;
      }

      // Strip any numbered heading/outline line ("N. Title", "N.\tTitle") that
      // appears before the first verse (>>>). These are structural outlines only.
      if (!seenVerse && RegExp(r'^\d+\.\s').hasMatch(t)) {
        continue;
      }

      // Verse text line (>>> prefix)
      if (t.startsWith('>>>')) {
        seenVerse = true;
        final verse = t.length > 4 ? t.substring(4) : (t.length > 3 ? t.substring(3) : '');
        segs.add(_VerseSeg(verse));
        continue;
      }

      // Prose / commentary — also marks end of preamble
      seenVerse = true;
      segs.add(_ProseSeg(raw.trimRight()));
    }

    return segs;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = _extractSectionTitle(entry.commentaryText);
    final headerLabel = title != null ? 'Commentary: $title' : 'Commentary';
    final segs = _parseSegments(entry.commentaryText);

    // Bottom sheet with sticky header: Column + Expanded so header stays pinned.
    if (forBottomSheet && scrollController != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(label: headerLabel, onClose: onClose, forBottomSheet: true),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: SelectionArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: _SegmentBody(segs: segs, forBottomSheet: true),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Bottom sheet without controller (fallback — should not normally occur)
    if (forBottomSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(label: headerLabel, onClose: onClose, forBottomSheet: true),
          const Divider(height: 1),
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: _SegmentBody(segs: segs, forBottomSheet: true),
            ),
          ),
        ],
      );
    }

    // Inline (non-bottom-sheet) variant with decorative border
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 8, bottom: 16, right: 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.commentaryBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.commentaryBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.commentaryBorder.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(label: headerLabel, onClose: onClose, forBottomSheet: false),
            SelectionArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _SegmentBody(segs: segs, forBottomSheet: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.label,
    required this.onClose,
    required this.forBottomSheet,
  });

  final String label;
  final VoidCallback onClose;
  final bool forBottomSheet;

  @override
  Widget build(BuildContext context) {
    final closeBtn = TextButton(
      onPressed: onClose,
      style: TextButton.styleFrom(
        foregroundColor: forBottomSheet
            ? AppColors.primary
            : AppColors.commentaryHeader,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Close'),
    );

    if (forBottomSheet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Lora',
                  color: AppColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            closeBtn,
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.commentaryHeader.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book, size: 20, color: AppColors.commentaryHeader),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Lora',
                color: AppColors.commentaryHeader,
                fontSize: 16,
              ),
            ),
          ),
          closeBtn,
        ],
      ),
    );
  }
}

// ── Content renderer ──────────────────────────────────────────────────────────

class _SegmentBody extends StatelessWidget {
  const _SegmentBody({required this.segs, required this.forBottomSheet});

  final List<_Seg> segs;
  final bool forBottomSheet;

  @override
  Widget build(BuildContext context) {
    /// Root verse lines (>>> in source): indented, bold, tight line spacing.
    final verseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Crimson Text',
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ) ??
        const TextStyle(
          fontFamily: 'Crimson Text',
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        );

    final proseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Crimson Text',
          fontSize: 18,
          height: 1.5,
          color: AppColors.textDark,
        ) ??
        const TextStyle(
          fontFamily: 'Crimson Text',
          fontSize: 18,
          height: 1.5,
          color: AppColors.textDark,
        );

    final refStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: 'Lora',
      color: forBottomSheet ? AppColors.mutedBrown : AppColors.commentaryHeader,
    );

    final children = <Widget>[];
    // Buffer consecutive verse lines so they become one BcvVerseText block
    final verseBuffer = <String>[];

    void flushVerse() {
      if (verseBuffer.isEmpty) return;
      // Space between commentary (or ref) above and verse block below, matching verse->commentary spacing.
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(Padding(
        padding: const EdgeInsets.only(left: 24),
        child: BcvVerseText(
          text: verseBuffer.join('\n'),
          style: verseStyle,
        ),
      ));
      verseBuffer.clear();
    }

    for (final seg in segs) {
      if (seg is _VerseSeg) {
        verseBuffer.add(seg.text);
        continue;
      }

      flushVerse();

      if (seg is _RefSeg) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 20));
        children.add(Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text('Verse ${seg.ref}', style: refStyle),
        ));
        children.add(const SizedBox(height: 6));
      } else if (seg is _BlankSeg) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 16));
      } else if (seg is _ProseSeg) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 12));
        children.add(Text(seg.text, style: proseStyle));
      }
    }
    flushVerse();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ── Segment types ─────────────────────────────────────────────────────────────

sealed class _Seg { const _Seg(); }

class _RefSeg extends _Seg {
  const _RefSeg(this.ref);
  final String ref;
}

class _VerseSeg extends _Seg {
  const _VerseSeg(this.text);
  final String text;
}

class _BlankSeg extends _Seg {
  const _BlankSeg();
}

class _ProseSeg extends _Seg {
  const _ProseSeg(this.text);
  final String text;
}
