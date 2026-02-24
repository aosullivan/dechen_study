import 'package:flutter/material.dart';

import '../../services/gateway_outline_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';
import 'gateway_landing_screen.dart';

class GatewayChapterScreen extends StatelessWidget {
  const GatewayChapterScreen({
    super.key,
    required this.chapterNumber,
  });

  final int chapterNumber;

  void _openChapterPicker(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    replaceAppPath('/gateway-to-knowledge');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const GatewayLandingScreen(),
      ),
    );
  }

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
            onPressed: () => _openChapterPicker(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _openChapterPicker(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: const Text('Back to Start'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openChapterPicker(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back to Start Page'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border, width: 1),
                      backgroundColor: const Color(0xFFF7F1E8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      minimumSize: const Size(1, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
