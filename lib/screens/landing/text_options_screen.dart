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
  static const String _rootTextPurchaseUrl = 'https://amzn.to/3N1bxAD';
  static const String _commentaryPurchaseUrl = 'https://amzn.to/3MsRxa5';
  static const Map<String, String> _amazonBaseByCountryCode = <String, String>{
    'US': 'https://www.amazon.com',
    'GB': 'https://www.amazon.co.uk',
    'UK': 'https://www.amazon.co.uk',
    'CA': 'https://www.amazon.ca',
    'AU': 'https://www.amazon.com.au',
    'DE': 'https://www.amazon.de',
    'FR': 'https://www.amazon.fr',
    'IT': 'https://www.amazon.it',
    'ES': 'https://www.amazon.es',
    'NL': 'https://www.amazon.nl',
    'PL': 'https://www.amazon.pl',
    'SE': 'https://www.amazon.se',
    'TR': 'https://www.amazon.com.tr',
    'BR': 'https://www.amazon.com.br',
    'MX': 'https://www.amazon.com.mx',
    'IN': 'https://www.amazon.in',
    'JP': 'https://www.amazon.co.jp',
    'SG': 'https://www.amazon.sg',
    'AE': 'https://www.amazon.ae',
    'SA': 'https://www.amazon.sa',
  };

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
    final viewport = MediaQuery.sizeOf(context);
    final isCompactPhone = viewport.width <= 430 && viewport.height <= 950;
    final options = <_StudyModeOption>[
      _StudyModeOption(
        icon: Icons.today_outlined,
        label: 'Daily Verses',
        onTap: () => _openDaily(context),
      ),
      _StudyModeOption(
        icon: Icons.quiz_outlined,
        label: 'Guess the Chapter',
        onTap: () => _openGuessTheChapter(context),
      ),
      _StudyModeOption(
        icon: Icons.fact_check_outlined,
        label: 'Quiz',
        onTap: () => _openQuiz(context),
      ),
      _StudyModeOption(
        icon: Icons.book_outlined,
        label: 'Read',
        onTap: () => _openRead(context),
      ),
      _StudyModeOption(
        icon: Icons.account_tree_outlined,
        label: 'Textual Structure',
        onTap: () => _openOverview(context),
      ),
    ];

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
          toolbarHeight: isCompactPhone ? 46 : 52,
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
          padding: EdgeInsets.symmetric(
            horizontal: isCompactPhone ? 12 : 18,
            vertical: isCompactPhone ? 4 : 8,
          ),
          children: [
            if (textId == 'bodhicaryavatara') ...[
              _BodhicaryavataraTextLandingCard(
                compact: isCompactPhone,
                onOpenReader: () => _openReaderView(context),
              ),
              SizedBox(height: isCompactPhone ? 6 : 10),
            ],
            for (final option in options)
              _OptionTile(
                compact: isCompactPhone,
                icon: option.icon,
                label: option.label,
                onTap: option.onTap,
              ),
            if (textId == 'bodhicaryavatara') ...[
              SizedBox(height: isCompactPhone ? 4 : 8),
              _PurchaseFooterLinks(
                compact: isCompactPhone,
                onBuyRootText: () => _openPurchaseLink(
                  context,
                  linkType: 'root_text',
                  usUrl: _rootTextPurchaseUrl,
                  localizedSearchTerm: 'Bodhicaryavatara Santideva root text',
                ),
                onBuyCommentary: () => _openPurchaseLink(
                  context,
                  linkType: 'commentary',
                  usUrl: _commentaryPurchaseUrl,
                  localizedSearchTerm:
                      'Bodhicaryavatara Sonam Tsemo commentary',
                ),
              ),
            ],
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

  void _openReaderView(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      unawaited(UsageMetricsService.instance.trackTextOptionTapped(
        textId: textId,
        targetMode: 'read',
      ));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BcvReadScreen(title: title),
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

  void _openPurchaseLink(
    BuildContext context, {
    required String linkType,
    required String usUrl,
    required String localizedSearchTerm,
  }) {
    final localeCode = Localizations.maybeLocaleOf(context)?.countryCode;
    final regionalUrl = _resolveRegionalAmazonUrl(
      usUrl: usUrl,
      countryCode: localeCode,
      localizedSearchTerm: localizedSearchTerm,
    );
    final opened = openExternalUrl(regionalUrl);
    unawaited(UsageMetricsService.instance.trackEvent(
      eventName: 'purchase_link_tapped',
      textId: textId,
      mode: 'text_options',
      properties: {
        'link_type': linkType,
        'country_code': localeCode?.toUpperCase(),
        'target_url': regionalUrl,
        'opened_in_web': opened,
      },
    ));
    if (!opened) {
      _showExternalLinkUnavailable(context);
    }
  }

  void _showExternalLinkUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('External links are currently available on web.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _resolveRegionalAmazonUrl({
    required String usUrl,
    required String localizedSearchTerm,
    required String? countryCode,
  }) {
    final normalizedCountryCode = countryCode?.toUpperCase().trim();
    if (normalizedCountryCode == null ||
        normalizedCountryCode.isEmpty ||
        normalizedCountryCode == 'US') {
      return usUrl;
    }

    final amazonBase = _amazonBaseByCountryCode[normalizedCountryCode];
    if (amazonBase == null) {
      return usUrl;
    }

    final encodedQuery = Uri.encodeQueryComponent(localizedSearchTerm);
    return '$amazonBase/s?k=$encodedQuery';
  }
}

class _BodhicaryavataraTextLandingCard extends StatelessWidget {
  const _BodhicaryavataraTextLandingCard({
    required this.compact,
    required this.onOpenReader,
  });

  final bool compact;
  final VoidCallback onOpenReader;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardBeige,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final canKeepImageOnRight = isWide || constraints.maxWidth >= 420;

            if (canKeepImageOnRight) {
              final coverWidth = isWide ? 120.0 : (compact ? 64.0 : 86.0);
              final gap = isWide ? 14.0 : 10.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _BodhicaryavataraTextLandingContent(
                      compact: compact && !isWide,
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: coverWidth,
                    child: _BookCoverCard(
                      onTap: onOpenReader,
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BodhicaryavataraTextLandingContent(
                  compact: true,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 86,
                    child: _BookCoverCard(
                      onTap: onOpenReader,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BodhicaryavataraTextLandingContent extends StatelessWidget {
  const _BodhicaryavataraTextLandingContent({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BODHICARYAVATARA • SANTIDEVA',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 9 : 12,
                    letterSpacing: compact ? 0.9 : 1.5,
                    color: AppColors.mutedBrown,
                  ) ??
              TextStyle(
                fontFamily: 'Crimson Text',
                fontSize: compact ? 9 : 12,
                letterSpacing: compact ? 0.9 : 1.5,
                color: AppColors.mutedBrown,
              ),
        ),
        SizedBox(height: compact ? 1 : 4),
        Text(
          'Bodhicaryavatara',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: compact ? 22 : 34,
                    height: 1.0,
                  ) ??
              TextStyle(
                fontFamily: 'Crimson Text',
                fontSize: compact ? 22 : 34,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
        ),
        SizedBox(height: compact ? 3 : 8),
        Text(
          'Read, explore the textual structure, reflect with daily verses, and quiz yourself. Commentary included.',
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: compact ? 12.5 : 14,
                    height: compact ? 1.2 : 1.4,
                  ) ??
              TextStyle(
                fontFamily: 'Lora',
                fontSize: compact ? 12.5 : 14,
                height: compact ? 1.2 : 1.4,
                color: AppColors.bodyText,
              ),
        ),
      ],
    );
  }
}

class _BookCoverCard extends StatelessWidget {
  const _BookCoverCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: AspectRatio(
          aspectRatio: 348 / 522,
          child: Image.asset(
            'assets/bodhicarya.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => Container(
              color: const Color(0xFFB2223B),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseFooterLinks extends StatelessWidget {
  const _PurchaseFooterLinks({
    required this.compact,
    required this.onBuyRootText,
    required this.onBuyCommentary,
  });

  final bool compact;
  final VoidCallback onBuyRootText;
  final VoidCallback onBuyCommentary;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: 'Lora',
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 2 : 4,
        top: compact ? 2 : 4,
        bottom: compact ? 6 : 10,
      ),
      child: Wrap(
        spacing: compact ? 16 : 20,
        runSpacing: compact ? 6 : 8,
        children: [
          TextButton(
            onPressed: onBuyRootText,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textDark,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: textStyle,
            ),
            child: const Text('Purchase root text'),
          ),
          TextButton(
            onPressed: onBuyCommentary,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textDark,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: textStyle,
            ),
            child: const Text('Purchase commentary'),
          ),
        ],
      ),
    );
  }
}

class _StudyModeOption {
  const _StudyModeOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.compact,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 12),
      color: AppColors.cardBeige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        dense: compact,
        minLeadingWidth: compact ? 26 : 40,
        minVerticalPadding: compact ? 0 : null,
        visualDensity:
            compact ? const VisualDensity(horizontal: 0, vertical: -3) : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 0 : 4,
        ),
        leading: Icon(icon, color: AppColors.primary, size: compact ? 20 : 24),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: compact ? 16 : 22,
              ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: compact ? 12 : 13,
          color: AppColors.mutedBrown,
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
