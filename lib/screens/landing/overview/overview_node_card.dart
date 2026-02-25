import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import 'overview_constants.dart';

/// A single tree node rendered as a compact rounded card.
///
/// Only the leading chevron (>) expands/collapses children; tapping the rest
/// of the card does not. The book icon at the trailing edge opens the verse panel.
class OverviewNodeCard extends StatelessWidget {
  const OverviewNodeCard({
    super.key,
    required this.path,
    required this.title,
    required this.depth,
    required this.hasChildren,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
    required this.onBookTap,
    this.verseRange,
  });

  final String path;
  final String title;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final bool isSelected;

  /// Pre-computed verse range (e.g. "v1.1ab", "v1.2-1.3"). Shown before the book icon.
  final String? verseRange;

  /// Expand / collapse (chevron tap only).
  final VoidCallback onTap;

  /// Show verses (book icon tap).
  final VoidCallback onBookTap;

  String get _shortNumber {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot + 1) : path;
  }

  @override
  Widget build(BuildContext context) {
    final indent = depth * OverviewConstants.indentPerLevel +
        OverviewConstants.leftPadding +
        (depth > 0 ? OverviewConstants.stubLength : 0);

    return SizedBox(
      height: OverviewConstants.nodeHeight,
      child: Padding(
        padding: EdgeInsets.only(left: indent),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(
                maxWidth: OverviewConstants.nodeMaxWidth),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : OverviewConstants.depthColor(depth),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border.withValues(alpha: 0.6),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chevron — only this expands/collapses (not the whole card).
                SizedBox(
                  width: 40,
                  height: 32,
                  child: hasChildren
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(4),
                            child: Center(
                              child: Icon(
                                isExpanded
                                    ? Icons.expand_more
                                    : Icons.chevron_right,
                                size: 16,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.mutedBrown,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                // Title + book area: absorb taps so only the chevron expands.
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {}, // No-op: do not expand/collapse on card tap.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_shortNumber. ',
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize:
                                        OverviewConstants.fontSizeForDepth(depth) -
                                            1,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.mutedBrown,
                                  ),
                                ),
                                TextSpan(
                                  text: title,
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize:
                                        OverviewConstants.fontSizeForDepth(depth),
                                    fontWeight:
                                        OverviewConstants.fontWeightForDepth(depth),
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Verse range (e.g. v1.1ab, v1.2-1.3) — before book icon.
                        if (verseRange != null && verseRange!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            verseRange!,
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 11,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.mutedBrown.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        // Book icon — opens verse panel.
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onBookTap,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.mutedBrown.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
