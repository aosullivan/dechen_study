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
    required this.isSelected,
    required this.onTap,
  });

  final String path;
  final String title;
  final int depth;
  final bool isSelected;
  final VoidCallback onTap;

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
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              constraints:
                  const BoxConstraints(maxWidth: OverviewConstants.nodeMaxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: OverviewConstants.fontSizeForDepth(depth),
                  fontWeight: OverviewConstants.fontWeightForDepth(depth),
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
