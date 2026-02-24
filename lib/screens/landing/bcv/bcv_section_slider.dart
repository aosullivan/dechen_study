import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import 'bcv_read_constants.dart';

/// One section entry in the flat list: path, title, depth.
typedef BcvSectionItem = ({String path, String title, int depth});

/// Right-side panel listing section hierarchy; tap to jump to section.
class BcvSectionSlider extends StatelessWidget {
  const BcvSectionSlider({
    super.key,
    required this.flatSections,
    required this.currentPath,
    required this.onSectionTap,
    required this.sectionNumberForDisplay,
    this.additionalHighlightedPaths = const <String>{},
    this.expandablePaths = const <String>{},
    this.expandedPaths = const <String>{},
    this.nonNavigablePaths = const <String>{},
    this.onToggleExpandPath,
    this.scrollController,
    this.height,
  });

  final List<BcvSectionItem> flatSections;
  final String currentPath;
  final ValueChanged<Map<String, String>> onSectionTap;
  final String Function(String path) sectionNumberForDisplay;
  final Set<String> additionalHighlightedPaths;
  final Set<String> expandablePaths;
  final Set<String> expandedPaths;
  final Set<String> nonNavigablePaths;
  final ValueChanged<String>? onToggleExpandPath;
  final ScrollController? scrollController;
  final double? height;

  /// True when this row starts a new top-level section group.
  static bool isTopLevelGroupStart(
      List<BcvSectionItem> flatSections, int index) {
    if (index <= 0 || index >= flatSections.length) return false;
    return flatSections[index].depth == 0;
  }

  static bool _isCooperatingConditionMainSection(BcvSectionItem item) {
    final segments = item.path.split('.');
    return segments.length == 2 && segments.first == '4';
  }

  /// True for 4.2/4.3/... main subsections under "The Cooperating Condition".
  /// This inserts separators between those six main blocks (4.1 to 4.6).
  static bool isCooperatingMainSectionStart(
      List<BcvSectionItem> flatSections, int index) {
    if (index <= 0 || index >= flatSections.length) return false;
    if (!_isCooperatingConditionMainSection(flatSections[index])) return false;
    for (var i = 0; i < index; i++) {
      if (_isCooperatingConditionMainSection(flatSections[i])) {
        return true;
      }
    }
    return false;
  }

  /// Extra visual spacing inserted before top-level section groups.
  static double extraTopPaddingForIndex(
      List<BcvSectionItem> flatSections, int index) {
    var total = 0.0;
    if (isTopLevelGroupStart(flatSections, index)) {
      total += BcvReadConstants.sectionSliderTopLevelGap;
    }
    if (isCooperatingMainSectionStart(flatSections, index)) {
      total += BcvReadConstants.sectionSliderCooperatingMainGap;
    }
    return total;
  }

  /// Extra vertical height before the section row at [index], including
  /// separators/gaps inserted above that row.
  static double extraHeightBeforeRow(
      List<BcvSectionItem> flatSections, int index) {
    var total = 0.0;
    for (var i = 1; i <= index && i < flatSections.length; i++) {
      total += extraTopPaddingForIndex(flatSections, i);
    }
    return total;
  }

  /// Total extra vertical height added to the slider via top-level separators.
  static double totalExtraHeight(List<BcvSectionItem> flatSections) {
    var total = 0.0;
    for (var i = 1; i < flatSections.length; i++) {
      total += extraTopPaddingForIndex(flatSections, i);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (flatSections.isEmpty) return const SizedBox.shrink();
    final raw = height ??
        BcvReadConstants.sectionSliderLineHeight *
            BcvReadConstants.sectionSliderVisibleLines;
    final sliderHeight = raw.toDouble();
    return Container(
      height: sliderHeight,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: flatSections.length,
        itemBuilder: (context, index) {
          final item = flatSections[index];
          final hasTopLevelSeparator =
              isTopLevelGroupStart(flatSections, index);
          final hasCooperatingMainSeparator =
              isCooperatingMainSectionStart(flatSections, index);
          final hasSeparator =
              hasTopLevelSeparator || hasCooperatingMainSeparator;
          final topPadding = extraTopPaddingForIndex(flatSections, index);
          final isCurrent = item.path == currentPath ||
              additionalHighlightedPaths.contains(item.path);
          final isExpandable = expandablePaths.contains(item.path);
          final isExpanded = expandedPaths.contains(item.path);
          final isNavigable = !nonNavigablePaths.contains(item.path);
          final isAncestor = currentPath.isNotEmpty &&
              (item.path == currentPath ||
                  currentPath.startsWith('${item.path}.'));
          final indent =
              item.depth * BcvReadConstants.sectionSliderIndentPerLevel;
          final numStr = sectionNumberForDisplay(item.path);
          final label =
              numStr.isNotEmpty ? '$numStr. ${item.title}' : item.title;
          return Container(
            padding: EdgeInsets.only(top: topPadding),
            decoration: hasSeparator
                ? BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.65),
                        width: BcvReadConstants
                            .sectionSliderTopLevelDividerThickness,
                      ),
                    ),
                  )
                : null,
            child: Material(
              color: isCurrent
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!isNavigable) {
                    if (isExpandable && onToggleExpandPath != null) {
                      onToggleExpandPath!(item.path);
                    }
                    return;
                  }
                  onSectionTap({
                    'section': item.path,
                    'path': item.path,
                    'title': item.title,
                  });
                },
                child: SizedBox(
                  height: BcvReadConstants.sectionSliderLineHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: indent),
                      child: Row(
                        children: [
                          if (isExpandable)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: IconButton(
                                key: Key('section_expand_${item.path}'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                    width: 18, height: 18),
                                iconSize: 16,
                                tooltip: isExpanded
                                    ? 'Collapse section'
                                    : 'Expand section',
                                color: AppColors.primary,
                                onPressed: onToggleExpandPath == null
                                    ? null
                                    : () => onToggleExpandPath!(item.path),
                                icon: Icon(
                                  isExpanded
                                      ? Icons.expand_more
                                      : Icons.chevron_right,
                                ),
                              ),
                            ),
                          if (isExpandable) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              label,
                              style: sectionListTextStyle(
                                context,
                                isCurrent: isCurrent,
                                isAncestor: isAncestor,
                                isNavigable: isNavigable,
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
              ),
            ),
          );
        },
      ),
    );
  }

  static TextStyle sectionListTextStyle(
    BuildContext context, {
    required bool isCurrent,
    required bool isAncestor,
    bool isNavigable = true,
  }) {
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lora',
              fontSize: BcvReadConstants.sectionListFontSize,
              height: BcvReadConstants.sectionListLineHeight /
                  BcvReadConstants.sectionListFontSize,
              color: isCurrent
                  ? AppColors.textDark
                  : isAncestor
                      ? AppColors.mutedBrown
                      : AppColors.primary.withValues(alpha: 0.9),
              fontWeight: isAncestor ? FontWeight.w600 : FontWeight.normal,
            ) ??
        TextStyle(
          fontFamily: 'Lora',
          fontSize: BcvReadConstants.sectionListFontSize,
          height: BcvReadConstants.sectionListLineHeight /
              BcvReadConstants.sectionListFontSize,
        );
    if (isNavigable) return base;
    return base.copyWith(
      color: AppColors.mutedBrown.withValues(alpha: 0.78),
      fontWeight: FontWeight.normal,
    );
  }
}
