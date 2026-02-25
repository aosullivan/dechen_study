import 'package:flutter/material.dart';

import '../../../services/bcv_verse_service.dart';
import '../../../services/verse_hierarchy_service.dart';
import '../../../utils/app_theme.dart';
import '../bcv/bcv_verse_text.dart';
import 'overview_constants.dart';

/// Shows the verses belonging to a single section in a scrollable panel.
/// Used as a persistent side panel on desktop and a bottom sheet on mobile.
class OverviewVersePanel extends StatelessWidget {
  const OverviewVersePanel({
    super.key,
    required this.sectionPath,
    required this.sectionTitle,
    required this.onClose,
    this.scrollController,
  });

  final String sectionPath;
  final String sectionTitle;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  String _baseRef(String ref) {
    final m = RegExp(r'^(\d+\.\d+)', caseSensitive: false).firstMatch(ref);
    return m?.group(1) ?? ref;
  }

  List<({String ref, String text})> _loadVerses() {
    final ownRefs = VerseHierarchyService.instance
        .getOwnVerseRefsForSectionSync(sectionPath);
    final treeRefs =
        VerseHierarchyService.instance.getTreeVerseRefsForSectionSync(
      sectionPath,
    );
    final refs = (ownRefs.isNotEmpty
            ? ownRefs
            : treeRefs.isNotEmpty
                ? treeRefs
                : VerseHierarchyService.instance
                    .getVerseRefsForSectionSync(sectionPath))
        .toList()
      ..sort(VerseHierarchyService.compareVerseRefs);

    final seen = <String>{};
    final verses = <({String ref, String text})>[];
    for (final ref in refs) {
      final idx = BcvVerseService.instance.getIndexForRefWithFallback(ref);
      if (idx != null) {
        final base = _baseRef(ref);
        final key = 'r:$base';
        if (!seen.add(key)) continue;
        final text = BcvVerseService.instance.getVerseAt(idx);
        if (text != null) verses.add((ref: base, text: text));
      }
    }
    return verses;
  }

  @override
  Widget build(BuildContext context) {
    final verses = _loadVerses();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBeige,
        border: Border(left: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          // Header.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sectionTitle,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.mutedBrown,
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // Verse list.
          Expanded(
            child: verses.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No verses in this section.\nTry selecting a more specific subsection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Ensure verse text has a finite width so wrap+indent works.
                      final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                          ? constraints.maxWidth
                          : OverviewConstants.versePanelWidth;
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: verses.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 24,
                          color: AppColors.borderLight,
                        ),
                        itemBuilder: (context, index) {
                          final v = verses[index];
                          return SizedBox(
                            width: width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verse ${v.ref}',
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mutedBrown,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                BcvVerseText(
                                  text: v.text,
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 15,
                                    height: 1.6,
                                    color: AppColors.bodyText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
