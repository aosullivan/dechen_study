import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/gateway_outline_service.dart';
import '../../services/usage_metrics_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';
import '../../widgets/dechen_home_action.dart';
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
  static const String _gatewayUsPurchaseUrl = 'https://amzn.to/3P0Puut';
  static const String _gatewayPurchaseSearchTerm =
      'Gateway to Knowledge Jamgon Mipham';
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
          actions: const [DechenHomeAction()],
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
                _GatewayHeroCard(
                  onBuyBook: () => _openGatewayPurchaseLink(context),
                ),
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

  void _openGatewayPurchaseLink(BuildContext context) {
    final localeCode = Localizations.maybeLocaleOf(context)?.countryCode;
    final targetUrl = _resolveRegionalAmazonUrl(
      usUrl: _gatewayUsPurchaseUrl,
      localizedSearchTerm: _gatewayPurchaseSearchTerm,
      countryCode: localeCode,
    );
    final opened = openExternalUrl(targetUrl);
    unawaited(UsageMetricsService.instance.trackEvent(
      eventName: 'purchase_link_tapped',
      textId: 'gateway_to_knowledge',
      mode: 'landing',
      properties: {
        'link_type': 'book',
        'country_code': localeCode?.toUpperCase(),
        'target_url': targetUrl,
        'opened_in_web': opened,
      },
    ));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('External links are currently available on web.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
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
    if (amazonBase == null) return usUrl;
    final encodedQuery = Uri.encodeQueryComponent(localizedSearchTerm);
    return '$amazonBase/s?k=$encodedQuery';
  }
}

class _GatewayHeroCard extends StatelessWidget {
  const _GatewayHeroCard({required this.onBuyBook});

  final VoidCallback onBuyBook;

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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onBuyBook,
                    icon: const Icon(Icons.local_library_outlined, size: 16),
                    label: const Text('Buy Book'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
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
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width <= 430 && viewport.height <= 950;
    final verySmall = viewport.width <= 375 && viewport.height <= 820;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 12),
      color: AppColors.cardBeige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? (verySmall ? 10 : 12) : 16,
          vertical: compact ? 2 : 4,
        ),
        leading: Icon(
          Icons.book_outlined,
          color: AppColors.primary,
          size: compact ? (verySmall ? 20 : 22) : 24,
        ),
        title: Text(
          '${chapter.number}. ${chapter.title}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: compact ? (verySmall ? 19.5 : 21) : 24,
              ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: compact ? (verySmall ? 13 : 14) : 13,
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
