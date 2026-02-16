import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import 'bcv_read_constants.dart';

/// Header for an expanded panel (label + subtitle, tap to collapse).
class BcvPanelHeader extends StatelessWidget {
  const BcvPanelHeader({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onCollapse,
  });

  final String label;
  final String subtitle;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBeige,
      child: InkWell(
        onTap: onCollapse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.expand_less, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle.isNotEmpty ? '$label: $subtitle' : label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.textDark,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsed strip (tap to expand).
class BcvCollapsedStrip extends StatelessWidget {
  const BcvCollapsedStrip({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.onExpand,
    this.compact = false,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onExpand;
  /// When true, use minimal padding (mobile: less whitespace).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < BcvReadConstants.laptopBreakpoint;
    final useCompact = compact || isMobile;
    final padding = useCompact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final iconSize = useCompact ? 18.0 : 20.0;
    final displayText = subtitle.isNotEmpty ? '$label: $subtitle' : label;
    return Material(
      color: AppColors.cardBeige,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.expand_more, size: iconSize, color: AppColors.primary),
              SizedBox(width: useCompact ? 6 : 8),
              Expanded(
                child: Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.textDark,
                        fontSize: useCompact ? 11 : 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!useCompact && onExpand != null)
                IconButton(
                  icon: Icon(Icons.expand_more,
                      size: iconSize, color: AppColors.primary),
                  tooltip: 'Expand',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onExpand,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical resize handle between panels.
class BcvVerticalResizeHandle extends StatelessWidget {
  const BcvVerticalResizeHandle({
    super.key,
    required this.onDragDelta,
  });

  final ValueChanged<double> onDragDelta;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => onDragDelta(d.delta.dy),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: Container(
          height: 6,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

/// One collapsible section: either expanded content or collapsed strip.
class BcvNavSection extends StatelessWidget {
  const BcvNavSection({
    super.key,
    required this.collapsed,
    required this.label,
    required this.subtitle,
    required this.expandedChild,
    required this.onExpand,
    required this.onCollapse,
    this.contentHeight,
    this.compactStrip = false,
  });

  final bool collapsed;
  final String label;
  final String subtitle;
  final Widget expandedChild;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final double? contentHeight;
  /// When true, collapsed strip uses minimal padding (mobile).
  final bool compactStrip;

  @override
  Widget build(BuildContext context) {
    Widget content = expandedChild;
    if (contentHeight != null && contentHeight! > 0) {
      final h = contentHeight!
          .clamp(BcvReadConstants.panelMinHeight, 400.0)
          .toDouble();
      content = SizedBox(
        height: h,
        child: SingleChildScrollView(child: content),
      );
    }
    // Stable keys on the direct children (no KeyedSubtree) so AnimatedCrossFade's
    // Stack/Positioned parent data is applied to these widgets, not to a wrapper.
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Column(
        key: ValueKey('nav_expanded_$label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          BcvPanelHeader(
            label: label,
            subtitle: subtitle,
            onCollapse: onCollapse,
          ),
          content,
        ],
      ),
      secondChild: BcvCollapsedStrip(
        key: ValueKey('nav_collapsed_$label'),
        label: label,
        subtitle: subtitle,
        onTap: onExpand,
        onExpand: onExpand,
        compact: compactStrip,
      ),
    );
  }
}
