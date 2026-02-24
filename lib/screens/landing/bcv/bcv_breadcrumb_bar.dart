import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import 'bcv_read_constants.dart';
import 'bcv_section_slider.dart';

/// Breadcrumb trail for the current section hierarchy; taps navigate to that section.
class BcvBreadcrumbBar extends StatelessWidget {
  const BcvBreadcrumbBar({
    super.key,
    required this.hierarchy,
    required this.sectionNumberForDisplay,
    required this.onSectionTap,
  });

  final List<Map<String, String>> hierarchy;
  final String Function(String section) sectionNumberForDisplay;
  final ValueChanged<Map<String, String>> onSectionTap;

  @override
  Widget build(BuildContext context) {
    if (hierarchy.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: BcvReadConstants.panelPaddingV,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(
          bottom:
              BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: _BreadcrumbTrail(
        hierarchy: hierarchy,
        sectionNumberForDisplay: sectionNumberForDisplay,
        onSectionTap: onSectionTap,
      ),
    );
  }
}

class _BreadcrumbTrail extends StatelessWidget {
  const _BreadcrumbTrail({
    required this.hierarchy,
    required this.sectionNumberForDisplay,
    required this.onSectionTap,
  });

  final List<Map<String, String>> hierarchy;
  final String Function(String section) sectionNumberForDisplay;
  final ValueChanged<Map<String, String>> onSectionTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = BcvSectionSlider.sectionListTextStyle(
      context,
      isCurrent: false,
      isAncestor: false,
    );
    final separatorStyle = baseStyle.copyWith(color: AppColors.mutedBrown);

    final spans = <InlineSpan>[];
    for (var i = 0; i < hierarchy.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: ' › ', style: separatorStyle));
      }
      final item = hierarchy[i];
      final isCurrent = i == hierarchy.length - 1;
      final title = item['title'] ?? '';
      final section = item['section'] ?? item['path'] ?? '';
      final numDisplay = sectionNumberForDisplay(section);
      final label = numDisplay.isNotEmpty ? '$numDisplay. $title' : title;
      final style = BcvSectionSlider.sectionListTextStyle(
        context,
        isCurrent: isCurrent,
        isAncestor: false,
      );
      final recognizer = TapGestureRecognizer()
        ..onTap = () => onSectionTap(item);
      spans.add(
        TextSpan(
          text: label,
          style: style,
          recognizer: recognizer,
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: RichText(
        text: TextSpan(style: baseStyle, children: spans),
        softWrap: true,
      ),
    );
  }
}
