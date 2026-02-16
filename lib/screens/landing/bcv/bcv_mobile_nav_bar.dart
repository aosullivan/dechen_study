import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import 'bcv_read_constants.dart';

/// Single row of three segments (Chapter | Section | Breadcrumb) for mobile.
/// Tap a segment to expand that pane; tap again to collapse. One pane expanded at a time.
/// No separate icons — text-only for clarity and equal weight.
class BcvMobileNavBar extends StatelessWidget {
  const BcvMobileNavBar({
    super.key,
    required this.chaptersCollapsed,
    required this.sectionCollapsed,
    required this.breadcrumbCollapsed,
    required this.onToggleChapter,
    required this.onToggleSection,
    required this.onToggleBreadcrumb,
  });

  final bool chaptersCollapsed;
  final bool sectionCollapsed;
  final bool breadcrumbCollapsed;
  final VoidCallback onToggleChapter;
  final VoidCallback onToggleSection;
  final VoidCallback onToggleBreadcrumb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'Lora',
          fontSize: 13,
          color: AppColors.textDark,
        );
    return Material(
      color: AppColors.cardBeige,
      child: Container(
        height: BcvReadConstants.mobileNavBarHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            _Segment(
              label: 'Chapter',
              selected: !chaptersCollapsed,
              onTap: onToggleChapter,
              theme: theme,
            ),
            _Segment(
              label: 'Section',
              selected: !sectionCollapsed,
              onTap: onToggleSection,
              theme: theme,
            ),
            _Segment(
              label: 'Breadcrumb',
              selected: !breadcrumbCollapsed,
              onTap: onToggleBreadcrumb,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: theme?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? AppColors.textDark
                    : AppColors.primary.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
