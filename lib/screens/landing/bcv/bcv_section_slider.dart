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
    this.scrollController,
    this.height,
  });

  final List<BcvSectionItem> flatSections;
  final String currentPath;
  final ValueChanged<Map<String, String>> onSectionTap;
  final String Function(String path) sectionNumberForDisplay;
  final ScrollController? scrollController;
  final double? height;

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
        color: AppColors.cardBeige,
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
          final isCurrent = item.path == currentPath;
          final isAncestor = currentPath.isNotEmpty &&
              (item.path == currentPath ||
                  currentPath.startsWith('${item.path}.'));
          final indent = item.depth * BcvReadConstants.sectionSliderIndentPerLevel;
          final numStr = sectionNumberForDisplay(item.path);
          final label =
              numStr.isNotEmpty ? '$numStr. ${item.title}' : item.title;
          return Material(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            child: InkWell(
              onTap: () => onSectionTap({
                'section': item.path,
                'path': item.path,
                'title': item.title,
              }),
              child: SizedBox(
                height: BcvReadConstants.sectionSliderLineHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: indent),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'Lora',
                            fontSize: 12,
                            color: isCurrent
                                ? AppColors.textDark
                                : isAncestor
                                    ? AppColors.mutedBrown
                                    : AppColors.primary.withValues(alpha: 0.9),
                            fontWeight:
                                isAncestor ? FontWeight.w600 : FontWeight.normal,
                          ) ??
                          const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
