import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/usage_metrics_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';
import 'bcv_file_quiz_screen.dart';
import 'bcv_quiz_screen.dart';
import 'bcv_read_screen.dart';
import 'daily_verse_screen.dart';
import 'textual_overview_screen.dart';

/// Shows top-level study modes for a text.
class TextOptionsScreen extends StatefulWidget {
  const TextOptionsScreen({
    super.key,
    required this.textId,
    required this.title,
  });

  final String textId;
  final String title;

  @override
  State<TextOptionsScreen> createState() => _TextOptionsScreenState();
}

class _TextOptionsScreenState extends State<TextOptionsScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-warm services so the read screen opens quickly.
    if (widget.textId == 'bodhicaryavatara') {
      BcvVerseService.instance.preload();
      VerseHierarchyService.instance.preload();
    }
  }

  String get textId => widget.textId;
  String get title => widget.title;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _restoreLandingPath();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.landingBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _OptionTile(
              icon: Icons.today_outlined,
              label: 'Daily Verses',
              onTap: () => _openDaily(context),
            ),
            _OptionTile(
              icon: Icons.quiz_outlined,
              label: 'Guess the Chapter',
              onTap: () => _openGuessTheChapter(context),
            ),
            _OptionTile(
              icon: Icons.fact_check_outlined,
              label: 'Quiz',
              onTap: () => _openQuiz(context),
            ),
            _OptionTile(
              icon: Icons.book_outlined,
              label: 'Read',
              onTap: () => _openRead(context),
            ),
            _OptionTile(
              icon: Icons.account_tree_outlined,
              label: 'Textual Structure',
              onTap: () => _openOverview(context),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreLandingPath() {
    if (textId == 'bodhicaryavatara') {
      replaceAppPath('/');
    }
  }

  void _openDaily(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      unawaited(UsageMetricsService.instance.trackTextOptionTapped(
        textId: textId,
        targetMode: 'daily',
      ));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DailyVerseScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Daily');
    }
  }

  Future<void> _openRead(BuildContext context) async {
    if (textId == 'bodhicaryavatara') {
      unawaited(UsageMetricsService.instance.trackTextOptionTapped(
        textId: textId,
        targetMode: 'read',
      ));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ReadChapterSelectionScreen(
            title: title,
            textId: textId,
          ),
        ),
      );
    } else {
      _showComingSoon(context, 'Read');
    }
  }

  void _openGuessTheChapter(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      unawaited(UsageMetricsService.instance.trackTextOptionTapped(
        textId: textId,
        targetMode: 'guess_chapter',
      ));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BcvQuizScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Guess the Chapter');
    }
  }

  void _openQuiz(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      unawaited(UsageMetricsService.instance.trackTextOptionTapped(
        textId: textId,
        targetMode: 'quiz',
      ));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BcvFileQuizScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Quiz');
    }
  }

  void _openOverview(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      unawaited(UsageMetricsService.instance.trackTextOptionTapped(
        textId: textId,
        targetMode: 'overview',
      ));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TextualOverviewScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Textual Structure');
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ReadChapterSelectionScreen extends StatefulWidget {
  const _ReadChapterSelectionScreen({
    required this.title,
    required this.textId,
  });

  final String title;
  final String textId;

  @override
  State<_ReadChapterSelectionScreen> createState() =>
      _ReadChapterSelectionScreenState();
}

class _ReadChapterSelectionScreenState
    extends State<_ReadChapterSelectionScreen> {
  late final Future<List<BcvChapter>> _chaptersFuture =
      BcvVerseService.instance.getChapters();
  Bookmark? _bookmark;

  @override
  void initState() {
    super.initState();
    BookmarkService.instance.load().then((b) {
      if (b != null && mounted) setState(() => _bookmark = b);
    });
  }

  void _resumeReading() {
    final bm = _bookmark;
    if (bm == null) return;
    unawaited(UsageMetricsService.instance.trackEvent(
      eventName: 'read_resume_tapped',
      textId: widget.textId,
      mode: 'read',
      chapterNumber: bm.chapterNumber,
      verseRef: bm.verseRef,
    ));
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => BcvReadScreen(
        title: widget.title,
        initialChapterNumber: bm.chapterNumber,
        scrollToVerseIndex: bm.verseIndex,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.landingBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Read',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<BcvChapter>>(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Could not load chapters.',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        unawaited(UsageMetricsService.instance.trackEvent(
                          eventName: 'read_open_without_chapter',
                          textId: widget.textId,
                          mode: 'read',
                        ));
                        Navigator.of(context)
                            .pushReplacement(MaterialPageRoute<void>(
                          builder: (_) => BcvReadScreen(title: widget.title),
                        ));
                      },
                      child: const Text('Open Read'),
                    ),
                  ],
                ),
              ),
            );
          }

          final chapters = snapshot.data ?? const <BcvChapter>[];
          if (chapters.isEmpty) {
            return Center(
              child: Text(
                'No chapters available.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final bm = _bookmark;
          final chapterTitle = bm != null
              ? chapters
                  .where((c) => c.number == bm.chapterNumber)
                  .map((c) => c.title)
                  .firstOrNull
              : null;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: chapters.length + (bm != null ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (bm != null && index == 0) {
                return _ResumeReadingCard(
                  verseRef: bm.verseRef,
                  chapterTitle: chapterTitle,
                  onTap: _resumeReading,
                );
              }
              final chapterIndex = bm != null ? index - 1 : index;
              final chapter = chapters[chapterIndex];
              return Card(
                margin: EdgeInsets.zero,
                color: AppColors.cardBeige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    unawaited(UsageMetricsService.instance.trackEvent(
                      eventName: 'read_chapter_selected',
                      textId: widget.textId,
                      mode: 'read',
                      chapterNumber: chapter.number,
                      properties: {'chapter_title': chapter.title},
                    ));
                    Navigator.of(context)
                        .pushReplacement(MaterialPageRoute<void>(
                      builder: (_) => BcvReadScreen(
                        title: widget.title,
                        initialChapterNumber: chapter.number,
                      ),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${chapter.number}.',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(height: 1.25),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chapter.title,
                            softWrap: true,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(height: 1.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ResumeReadingCard extends StatelessWidget {
  const _ResumeReadingCard({
    required this.onTap,
    this.verseRef,
    this.chapterTitle,
  });

  final VoidCallback onTap;
  final String? verseRef;
  final String? chapterTitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[];
    if (chapterTitle != null) subtitle.add(chapterTitle!);
    if (verseRef != null) subtitle.add('Verse $verseRef');

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.bookmark_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume Reading',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedBrown,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
