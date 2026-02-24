import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/gateway_outline_service.dart';
import '../../services/usage_metrics_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';
import 'gateway_chapter_screen.dart';

class GatewayLandingScreen extends StatefulWidget {
  const GatewayLandingScreen({
    super.key,
    this.initialChapterNumber,
  });

  final int? initialChapterNumber;

  @override
  State<GatewayLandingScreen> createState() => _GatewayLandingScreenState();
}

class _GatewayLandingScreenState extends State<GatewayLandingScreen> {
  late final Future<List<GatewayOutlineChapter>> _chaptersFuture =
      GatewayOutlineService.instance.getChapters();
  bool _openedInitialChapter = false;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          replaceAppPath('/');
          return;
        }
        if (hasBrowserBackTarget()) {
          navigateBrowserBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.landingBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Gateway to Knowledge',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
          leading: _canShowTopBackButton(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () => _handleBackPressed(context),
                )
              : null,
        ),
        body: FutureBuilder<List<GatewayOutlineChapter>>(
          future: _chaptersFuture,
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

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load Gateway chapters.',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final chapters = snapshot.data ?? const <GatewayOutlineChapter>[];
            _openInitialChapterIfNeeded(chapters);

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              children: [
                _GatewayHeroCard(),
                const SizedBox(height: 10),
                _GatewayChapterGrid(
                  chapters: chapters,
                  onOpenChapter: (chapter) => _openChapter(context, chapter),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _canShowTopBackButton(BuildContext context) {
    if (Navigator.of(context).canPop()) return true;
    return hasBrowserBackTarget();
  }

  void _handleBackPressed(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (hasBrowserBackTarget()) {
      navigateBrowserBack();
    }
  }

  void _openInitialChapterIfNeeded(List<GatewayOutlineChapter> chapters) {
    final chapterNumber = widget.initialChapterNumber;
    if (_openedInitialChapter || chapterNumber == null || chapters.isEmpty) {
      return;
    }
    final target = chapters
        .where((chapter) => chapter.number == chapterNumber)
        .firstOrNull;
    if (target == null) return;

    _openedInitialChapter = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openChapter(context, target);
    });
  }

  void _openChapter(BuildContext context, GatewayOutlineChapter chapter) {
    unawaited(UsageMetricsService.instance.trackEvent(
      eventName: 'gateway_chapter_opened',
      textId: 'gateway_to_knowledge',
      mode: 'chapter',
      chapterNumber: chapter.number,
      properties: {
        'chapter_title': chapter.title,
        'opened_in_web': false,
      },
    ));
    pushAppPath('/gateway-to-knowledge/chapter-${chapter.number}');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GatewayChapterScreen(chapterNumber: chapter.number),
      ),
    );
  }
}

class _GatewayHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardBeige,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JAMGON JU MIPHAM',
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
                  'Gateway to Knowledge',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 38,
                            height: 1,
                          ) ??
                      const TextStyle(
                        fontFamily: 'Crimson Text',
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a chapter breakdown. Each button opens its own chapter page.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                            height: 1.45,
                          ) ??
                      const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.bodyText,
                      ),
                ),
              ],
            );

            final cover = SizedBox(
              width: isWide ? 160 : 132,
              child: const _GatewayCoverImage(),
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: 10),
                  cover,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                cover,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GatewayChapterGrid extends StatelessWidget {
  const _GatewayChapterGrid({
    required this.chapters,
    required this.onOpenChapter,
  });

  final List<GatewayOutlineChapter> chapters;
  final ValueChanged<GatewayOutlineChapter> onOpenChapter;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: AppColors.cardBeige,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No chapters found.'),
        ),
      );
    }
    return Column(
      children: [
        for (final chapter in chapters)
          _GatewayChapterTile(
            chapter: chapter,
            onTap: () => onOpenChapter(chapter),
          ),
      ],
    );
  }
}

class _GatewayChapterTile extends StatelessWidget {
  const _GatewayChapterTile({
    required this.chapter,
    required this.onTap,
  });

  final GatewayOutlineChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBeige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.book_outlined, color: AppColors.primary),
        title: Text(
          'Chapter ${chapter.number}: ${chapter.title}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 13,
          color: AppColors.mutedBrown,
        ),
      ),
    );
  }
}

class _GatewayCoverImage extends StatelessWidget {
  const _GatewayCoverImage();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 907 / 1360,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.borderLight),
          color: const Color(0xFFF6F2EB),
        ),
        child: Image.asset(
          'assets/gateway.jpg',
          fit: BoxFit.contain,
          errorBuilder: (context, _, __) {
            return Container(
              color: const Color(0xFFA4B8CF),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF203B73),
                size: 40,
              ),
            );
          },
        ),
      ),
    );
  }
}
