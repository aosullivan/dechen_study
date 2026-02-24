import 'package:flutter/material.dart';

import '../../services/gateway_outline_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';

class GatewayChapterScreen extends StatelessWidget {
  const GatewayChapterScreen({
    super.key,
    required this.chapterNumber,
  });

  final int chapterNumber;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) replaceAppPath('/gateway-to-knowledge');
      },
      child: Scaffold(
        backgroundColor: AppColors.landingBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Gateway Chapter $chapterNumber',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: FutureBuilder<GatewayOutlineChapter?>(
          future: GatewayOutlineService.instance.getChapter(chapterNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final chapter = snapshot.data;
            if (chapter == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not find chapter $chapterNumber.',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              children: [
                _ChapterIntroCard(chapter: chapter),
                const SizedBox(height: 10),
                ...chapter.sections.map(
                  (section) => _GatewaySectionTile(section: section),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChapterIntroCard extends StatelessWidget {
  const _ChapterIntroCard({required this.chapter});

  final GatewayOutlineChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardBeige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHAPTER ${chapter.number}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: AppColors.mutedBrown,
                      ) ??
                  const TextStyle(
                    fontFamily: 'Crimson Text',
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: AppColors.mutedBrown,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              chapter.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ) ??
                  const TextStyle(
                    fontFamily: 'Crimson Text',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '${chapter.sections.length} outline points',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedBrown,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GatewaySectionTile extends StatelessWidget {
  const _GatewaySectionTile({required this.section});

  final GatewayOutlineSection section;

  @override
  Widget build(BuildContext context) {
    final depth = section.depth.clamp(0, 7);
    final indent = depth * 14.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        color: AppColors.cardBeige,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${section.path} ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.3,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
