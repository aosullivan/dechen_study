import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import 'overview_constants.dart';

/// A single tree node rendered as a compact rounded card.
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
    this.onExpandTap,
  });

  final String path;
  final String title;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onExpandTap;

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
      child: Row(
        children: [
          SizedBox(width: indent),
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
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
                  children: [
                    SizedBox(
                      width: 20,
                      child: hasChildren
                          ? IconButton(
                              onPressed: onExpandTap,
                              padding: EdgeInsets.zero,
                              splashRadius: 14,
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_more
                                    : Icons.chevron_right,
                                size: 16,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.mutedBrown,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
