import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

/// Animated overlay that highlights the current section in the verse list.
class BcvSectionOverlay extends StatelessWidget {
  const BcvSectionOverlay({
    super.key,
    required this.animationId,
    this.rectFrom,
    this.rectTo,
  });

  final int animationId;
  final Rect? rectFrom;
  final Rect? rectTo;

  @override
  Widget build(BuildContext context) {
    if (rectTo == null) return const SizedBox.shrink();
    // Do not wrap in Positioned.fill here — the screen already wraps this
    // in Positioned.fill, so we must not add a second one (would cause
    // "Competing ParentDataWidgets").
    return TweenAnimationBuilder<Rect?>(
      key: ValueKey('section_overlay_$animationId'),
      tween: RectTween(
        begin: rectFrom ?? rectTo,
        end: rectTo,
      ),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, rect, child) {
        if (rect == null) return const SizedBox.shrink();
        final w = rect.width;
        final h = rect.height;
        if (w.isNaN || h.isNaN || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: rect.left,
              top: rect.top,
              width: w,
              height: h,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
