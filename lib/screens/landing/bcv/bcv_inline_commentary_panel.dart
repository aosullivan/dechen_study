import 'package:flutter/material.dart';

import '../../../services/bcv_verse_service.dart';
import '../../../services/commentary_service.dart';
import '../../../utils/app_theme.dart';
import 'bcv_verse_text.dart';

/// Inline commentary panel: verse ref(s), verse text, and commentary body.
/// Used in the read screen and in the mobile commentary bottom sheet.
class BcvInlineCommentaryPanel extends StatelessWidget {
  const BcvInlineCommentaryPanel({
    super.key,
    required this.entry,
    required this.verseService,
    required this.onClose,
    this.forBottomSheet = false,
  });

  final CommentaryEntry entry;
  final BcvVerseService verseService;
  final VoidCallback onClose;
  /// When true, uses a minimal style (single background, no colored header box).
  final bool forBottomSheet;

  static const Color _commentaryBg = AppColors.commentaryBg;
  static const Color _commentaryBorder = AppColors.commentaryBorder;
  static const Color _commentaryHeader = AppColors.commentaryHeader;

  /// Strip verse ref lines and verse text from commentary body so we show verses once at top.
  static final Map<String, String> _commentaryBodyCache = {};
  static String commentaryOnlyBody(
      CommentaryEntry entry, BcvVerseService verseService) {
    final cacheKey = entry.commentaryText;
    final cached = _commentaryBodyCache[cacheKey];
    if (cached != null) return cached;
    String body = entry.commentaryText;
    for (final ref in entry.refsInBlock) {
      body = body.replaceAll(
          RegExp('^${RegExp.escape(ref)}\\s*\$', multiLine: true), '');
      final verseText = verseService.getIndexForRef(ref) != null
          ? verseService.getVerseAt(verseService.getIndexForRef(ref)!)
          : null;
      if (verseText != null && verseText.isNotEmpty) {
        body = body.replaceAll(verseText, '');
      }
    }
    final result = body.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    _commentaryBodyCache[cacheKey] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final verseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    final headingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'Lora',
          color: forBottomSheet ? AppColors.bodyText : _commentaryHeader,
        );
    final commentaryOnly = commentaryOnlyBody(entry, verseService);

    if (forBottomSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                Text(
                  'Commentary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Lora',
                    color: AppColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClose,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: _buildContent(context, verseStyle, headingStyle, commentaryOnly),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 8, bottom: 16, right: 0),
      child: Container(
        decoration: BoxDecoration(
          color: _commentaryBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _commentaryBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: _commentaryBorder.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _commentaryHeader.withValues(alpha: 0.15),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book, size: 20, color: _commentaryHeader),
                  const SizedBox(width: 8),
                  Text(
                    'Commentary',
                    style: headingStyle?.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onClose,
                      style: TextButton.styleFrom(
                        foregroundColor: _commentaryHeader,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildContent(context, verseStyle, headingStyle, commentaryOnly),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TextStyle verseStyle,
    TextStyle? headingStyle,
    String commentaryOnly,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.refsInBlock.length == 1) ...[
          Text(
            'Verse ${entry.refsInBlock.single}',
            style: headingStyle,
          ),
          const SizedBox(height: 12),
          BcvVerseText(
            text: verseService.getIndexForRef(entry.refsInBlock.single) !=
                    null
                ? (verseService.getVerseAt(
                      verseService.getIndexForRef(
                          entry.refsInBlock.single)!,
                    ) ??
                    '')
                : '',
            style: verseStyle,
          ),
        ] else ...[
          Text(
            'Verses ${entry.refsInBlock.join(", ")}',
            style: headingStyle,
          ),
          const SizedBox(height: 12),
          ...entry.refsInBlock.map((ref) {
            final idx = verseService.getIndexForRef(ref);
            final text =
                idx != null ? verseService.getVerseAt(idx) : null;
            if (text == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verse $ref',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          fontFamily: 'Lora',
                          color: forBottomSheet
                              ? AppColors.mutedBrown
                              : _commentaryHeader,
                        ),
                  ),
                  const SizedBox(height: 4),
                  BcvVerseText(text: text, style: verseStyle),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
        Text('Commentary', style: headingStyle),
        const SizedBox(height: 12),
        Text(
          commentaryOnly,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'Crimson Text',
                fontSize: 18,
                height: 1.5,
                color: AppColors.textDark,
              ),
        ),
      ],
    );
  }
}
