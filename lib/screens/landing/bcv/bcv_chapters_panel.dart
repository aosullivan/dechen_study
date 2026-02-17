import 'package:flutter/material.dart';

import '../../../services/bcv_verse_service.dart';
import '../../../utils/app_theme.dart';
import 'bcv_read_constants.dart';

/// Right-side panel listing chapters; highlights current and supports tap-to-scroll.
class BcvChaptersPanel extends StatelessWidget {
  const BcvChaptersPanel({
    super.key,
    required this.chapters,
    required this.currentChapterNumber,
    required this.onChapterTap,
    this.height,
  });

  final List<BcvChapter> chapters;
  final int? currentChapterNumber;
  final ValueChanged<int> onChapterTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) return const SizedBox.shrink();
    final raw = height ?? BcvReadConstants.panelLineHeight * 5;
    final h = raw.clamp(BcvReadConstants.panelMinHeight, 400.0).toDouble();
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'Lora',
          fontSize: BcvReadConstants.panelFontSize,
          color: AppColors.textDark,
        ) ??
        TextStyle(
            fontFamily: 'Lora',
            fontSize: BcvReadConstants.panelFontSize,
            color: AppColors.textDark);
    return SizedBox(
      height: h,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: BcvReadConstants.panelPaddingH,
          vertical: BcvReadConstants.panelPaddingV,
        ),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final ch = chapters[index];
          final isCurrent = ch.number == currentChapterNumber;
          return Material(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            child: InkWell(
              onTap: () => onChapterTap(ch.number),
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: BcvReadConstants.panelLineHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ch ${ch.number}: ${ch.title}',
                    style: style.copyWith(
                      color: isCurrent
                          ? AppColors.textDark
                          : AppColors.primary.withValues(alpha: 0.9),
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
