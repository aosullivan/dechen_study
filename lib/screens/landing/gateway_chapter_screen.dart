import 'package:flutter/material.dart';

import '../../services/gateway_rich_content_service.dart';
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
        body: FutureBuilder<GatewayRichChapter?>(
          future: GatewayRichContentService.instance.getChapter(chapterNumber),
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

            final topicAnchors = _buildTopicAnchors(chapter);
            final topicLookup = _buildTopicLookup(topicAnchors);

            Future<void> openTopic(String label) async {
              final key = _resolveTopicKey(label, topicLookup);
              final targetContext = key?.currentContext;
              if (targetContext == null) return;
              await Scrollable.ensureVisible(
                targetContext,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: 0.06,
              );
            }

            bool canOpenTopic(String label) =>
                _resolveTopicKey(label, topicLookup) != null;

            return SelectionArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                children: [
                  _ChapterIntroCard(
                    chapter: chapter,
                    topics: topicAnchors.map((anchor) => anchor.topic).toList(),
                    onOpenTopic: (label) {
                      openTopic(label);
                    },
                    canOpenTopic: canOpenTopic,
                  ),
                  const SizedBox(height: 12),
                  ...topicAnchors.map(
                    (anchor) => RepaintBoundary(
                      child: _GatewayTopicCard(
                        key: anchor.key,
                        topic: anchor.topic,
                        onChipTap: (label) {
                          openTopic(label);
                        },
                        canOpenTopic: canOpenTopic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChapterIntroCard extends StatelessWidget {
  const _ChapterIntroCard({
    required this.chapter,
    required this.topics,
    required this.onOpenTopic,
    required this.canOpenTopic,
  });

  final GatewayRichChapter chapter;
  final List<GatewayRichTopic> topics;
  final ValueChanged<String> onOpenTopic;
  final bool Function(String topicTitle) canOpenTopic;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF8), Color(0xFFF6EFE2)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showCover = constraints.maxWidth >= 650;
            final text = Column(
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
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ) ??
                      const TextStyle(
                        fontFamily: 'Crimson Text',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 2),
                Text(
                  'Topics',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedBrown,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                for (var i = 0; i < topics.length; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 14, top: 2),
                    child: _TopicLink(
                      label: topics[i].title,
                      enabled: canOpenTopic(topics[i].title),
                      onTap: () => onOpenTopic(topics[i].title),
                    ),
                  ),
              ],
            );
            if (!showCover) return text;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: 14),
                SizedBox(
                  width: 86,
                  child: AspectRatio(
                    aspectRatio: 907 / 1360,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/gateway.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Container(
                          color: const Color(0xFFA4B8CF),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFF203B73),
                          ),
                        ),
                      ),
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

class _TopicLink extends StatelessWidget {
  const _TopicLink({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        );

    final isSkandha = _isSkandhaLabel(label);
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _IconBadge(
              icon: _iconForLabel(label),
              size: 10,
              backgroundColor: isSkandha ? _skandhaBadgeBg : null,
              borderColor: isSkandha ? _skandhaBadgeBorder : null,
              iconColor: isSkandha ? _skandhaIconColor : null,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: textStyle)),
        ],
      ),
    );

    if (!enabled) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _TopicAnchor {
  const _TopicAnchor({
    required this.topic,
    required this.key,
  });

  final GatewayRichTopic topic;
  final GlobalKey key;
}

class _GatewayTopicCard extends StatelessWidget {
  const _GatewayTopicCard({
    super.key,
    required this.topic,
    required this.onChipTap,
    required this.canOpenTopic,
  });

  final GatewayRichTopic topic;
  final ValueChanged<String> onChipTap;
  final bool Function(String topicTitle) canOpenTopic;

  @override
  Widget build(BuildContext context) {
    final blocks = topic.blocks;
    final children = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.type == 'ul' &&
          block.styleClass == 'sense-list' &&
          i + 2 < blocks.length &&
          blocks[i + 1].type == 'ul' &&
          blocks[i + 1].styleClass == 'sense-list' &&
          blocks[i + 2].type == 'ul' &&
          blocks[i + 2].styleClass == 'sense-list') {
        children.add(
          RepaintBoundary(
            child: _TriadCards(
              columns: [
                ('Faculties', blocks[i].items, _TriadCategory.faculties),
                ('Objects', blocks[i + 1].items, _TriadCategory.objects),
                (
                  'Consciousnesses',
                  blocks[i + 2].items,
                  _TriadCategory.consciousnesses
                ),
              ],
            ),
          ),
        );
        i += 2;
        continue;
      }
      // Skip subset-title + 3 sense-list-subset blocks (already shown via
      // the classification-summary list above).
      if (block.type == 'p' &&
          block.styleClass == 'subset-title' &&
          i + 3 < blocks.length &&
          blocks[i + 1].type == 'ul' &&
          blocks[i + 1].styleClass == 'sense-list-subset' &&
          blocks[i + 2].type == 'ul' &&
          blocks[i + 2].styleClass == 'sense-list-subset' &&
          blocks[i + 3].type == 'ul' &&
          blocks[i + 3].styleClass == 'sense-list-subset') {
        var skipCount = 3;
        if (i + 4 < blocks.length &&
            blocks[i + 4].type == 'p' &&
            blocks[i + 4].styleClass == 'subset-note') {
          skipCount = 4;
        }
        i += skipCount;
        continue;
      }
      if (block.type == 'ul' &&
          block.styleClass == 'duality-list' &&
          i + 1 < blocks.length &&
          blocks[i + 1].type == 'ul' &&
          blocks[i + 1].styleClass == 'duality-list') {
        children.add(
          RepaintBoundary(
            child: _DualityPairView(
              innerItems: blocks[i].items,
              outerItems: blocks[i + 1].items,
            ),
          ),
        );
        i += 1;
        continue;
      }
      if (block.type == 'chip') {
        final chipTexts = <String>[block.text ?? ''];
        while (i + 1 < blocks.length && blocks[i + 1].type == 'chip') {
          i += 1;
          chipTexts.add(blocks[i].text ?? '');
        }
        children.add(
          _GatewayChipWrap(
            items: chipTexts,
            onChipTap: onChipTap,
            canOpenTopic: canOpenTopic,
          ),
        );
        continue;
      }
      if (block.type == 'ul' &&
          block.styleClass == 'classification-summary') {
        final classMap = _buildClassificationIconMap(blocks);
        children.add(
          _ClassificationSummaryList(
            items: block.items,
            classificationIcons: classMap,
          ),
        );
        continue;
      }
      children.add(_GatewayBlockView(block: block));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(
                  icon: _iconForLabel(topic.title),
                  size: 18,
                  backgroundColor:
                      _isSkandhaLabel(topic.title) ? _skandhaBadgeBg : null,
                  borderColor:
                      _isSkandhaLabel(topic.title) ? _skandhaBadgeBorder : null,
                  iconColor:
                      _isSkandhaLabel(topic.title) ? _skandhaIconColor : null,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ) ??
                        const TextStyle(
                          fontFamily: 'Crimson Text',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 5),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _GatewayBlockView extends StatelessWidget {
  const _GatewayBlockView({required this.block});

  final GatewayRichBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'p':
        if (block.styleClass == 'triad-note') {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE8DCC8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBadge(icon: _iconForLabel(block.text ?? ''), size: 14),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    block.text ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.bodyText,
                          fontSize: 14,
                        ),
                  ),
                ),
              ],
            ),
          );
        }
        if (block.styleClass == 'callout') {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EA),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              block.text ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.bodyText,
                    fontSize: 15.5,
                  ),
            ),
          );
        }
        if (block.styleClass == 'topic-copy') {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              block.text ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.bodyText,
                    fontSize: 15.5,
                    height: 1.45,
                  ),
            ),
          );
        }
        if (block.styleClass == 'subset-title') {
          final subTitle = block.text ?? '';
          final isSkandha = _isSkandhaLabel(subTitle);
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 2),
            child: Row(
              children: [
                _IconBadge(
                  icon: _iconForLabel(subTitle),
                  size: 14,
                  backgroundColor: isSkandha ? _skandhaBadgeBg : null,
                  borderColor: isSkandha ? _skandhaBadgeBorder : null,
                  iconColor: isSkandha ? _skandhaIconColor : null,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    subTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            block.text ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  height: 1.4,
                ),
          ),
        );
      case 'ul':
      case 'ol':
        final isNumbered = block.type == 'ol';
        final items = block.items;
        if (block.styleClass == 'icon-list-grid' ||
            block.styleClass == 'links-grid') {
          return Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 180, maxWidth: 330),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEADFCF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (block.styleClass == 'links-grid')
                          Container(
                            width: 21,
                            height: 21,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8EC),
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: const Color(0xFFDAC8AD)),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.mutedBrown,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          )
                        else
                          _IconBadge(icon: _iconForLabel(items[i]), size: 14),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            items[i],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.bodyText,
                                  fontSize: 15,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
        if (block.styleClass == 'split-list' &&
            isNumbered &&
            items.length > 8) {
          final mid = (items.length / 2).ceil();
          final left = items.take(mid).toList();
          final right = items.skip(mid).toList();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 680) {
                  return _PlainList(items: items, isNumbered: true);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PlainList(
                        items: left,
                        isNumbered: true,
                        startIndex: 1,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _PlainList(
                        items: right,
                        isNumbered: true,
                        startIndex: mid + 1,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _PlainList(items: items, isNumbered: isNumbered),
        );
      case 'table':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(color: AppColors.borderLight),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF8EFE2)),
                  children: [
                    for (final header in block.headers)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          header,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                    fontSize: 15,
                                  ),
                        ),
                      ),
                  ],
                ),
                for (final row in block.rows)
                  TableRow(
                    children: [
                      for (var i = 0; i < block.headers.length; i++)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            i < row.length ? row[i] : '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.bodyText,
                                  fontSize: 15,
                                ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _GatewayChipWrap extends StatelessWidget {
  const _GatewayChipWrap({
    required this.items,
    this.onChipTap,
    this.canOpenTopic,
  });

  final List<String> items;
  final ValueChanged<String>? onChipTap;
  final bool Function(String topicTitle)? canOpenTopic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            _GatewayChipLink(
              label: item,
              enabled: canOpenTopic?.call(item) ?? false,
              onTap: onChipTap == null ? null : () => onChipTap!(item),
            ),
        ],
      ),
    );
  }
}

class _GatewayChipLink extends StatelessWidget {
  const _GatewayChipLink({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: enabled ? AppColors.primary : AppColors.bodyText,
          fontSize: 15,
          decoration: enabled ? TextDecoration.underline : TextDecoration.none,
          fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
        );
    final isSkandha = _isSkandhaLabel(label);
    final chipBg = isSkandha ? _skandhaChipBg : const Color(0xFFFFF9EF);
    final chipBorder =
        isSkandha ? _skandhaChipBorder : const Color(0xFFE7DAC7);
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(
            icon: _iconForLabel(label),
            size: 14,
            backgroundColor: isSkandha ? _skandhaBadgeBg : null,
            borderColor: isSkandha ? _skandhaBadgeBorder : null,
            iconColor: isSkandha ? _skandhaIconColor : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: textStyle),
        ],
      ),
    );

    if (!enabled || onTap == null) {
      return Container(
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: chipBorder),
        ),
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSkandha ? _skandhaChipBorder : const Color(0xFFE1D1BA)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}


class _TriadCards extends StatelessWidget {
  const _TriadCards({required this.columns});

  final List<(String title, List<String> items, _TriadCategory? category)>
      columns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final oneColumn = constraints.maxWidth < 860;
          if (oneColumn) {
            return Column(
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TriadCard(
                        title: column.$1,
                        items: column.$2,
                        category: column.$3),
                  ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length; i++)
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: i == columns.length - 1 ? 0 : 8),
                    child: _TriadCard(
                        title: columns[i].$1,
                        items: columns[i].$2,
                        category: columns[i].$3),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TriadCard extends StatelessWidget {
  const _TriadCard({
    required this.title,
    required this.items,
    this.category,
  });

  final String title;
  final List<String> items;
  final _TriadCategory? category;

  @override
  Widget build(BuildContext context) {
    final itemStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.bodyText,
          fontSize: 14.5,
        );
    final disabledItemStyle = itemStyle?.copyWith(
          color: AppColors.bodyText.withValues(alpha: 0.18),
        );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADFCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: _iconForLabel(title),
                size: 14,
                backgroundColor: category?.background,
                borderColor: category?.border,
                iconColor: category?.icon,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...items.map(
            (item) {
              final isDisabled = item.startsWith('~');
              final displayItem = isDisabled ? item.substring(1) : item;
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconBadge(
                      icon: _iconForLabel(displayItem),
                      size: 12,
                      backgroundColor: category?.background,
                      borderColor: category?.border,
                      iconColor: category?.icon,
                      opacity: isDisabled ? 0.18 : 1.0,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayItem,
                        style: isDisabled ? disabledItemStyle : itemStyle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DualityPairView extends StatelessWidget {
  const _DualityPairView({
    required this.innerItems,
    required this.outerItems,
  });

  final List<String> innerItems;
  final List<String> outerItems;

  @override
  Widget build(BuildContext context) {
    final pairs = <(String, String)>[];
    final count =
        innerItems.length < outerItems.length ? innerItems.length : outerItems.length;
    for (var i = 0; i < count; i++) {
      pairs.add((innerItems[i], outerItems[i]));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: _DualityHeader(
                  label: 'Inner Sources',
                  icon: Icons.adjust_outlined,
                  backgroundColor: _ayatanaInnerBg,
                  borderColor: _ayatanaInnerBorder,
                  iconColor: _ayatanaInnerIcon,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _DualityHeader(
                  label: 'Outer Sources',
                  icon: Icons.open_in_new_outlined,
                  backgroundColor: _ayatanaOuterBg,
                  borderColor: _ayatanaOuterBorder,
                  iconColor: _ayatanaOuterIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...pairs.map(
            (pair) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DualityItem(
                      label: pair.$1,
                      backgroundColor: _ayatanaInnerBg,
                      borderColor: _ayatanaInnerBorder,
                      iconColor: _ayatanaInnerIcon,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      size: 16,
                      color: AppColors.mutedBrown.withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    child: _DualityItem(
                      label: pair.$2,
                      backgroundColor: _ayatanaOuterBg,
                      borderColor: _ayatanaOuterBorder,
                      iconColor: _ayatanaOuterIcon,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DualityHeader extends StatelessWidget {
  const _DualityHeader({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _IconBadge(
            icon: icon,
            size: 12,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            iconColor: iconColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DualityItem extends StatelessWidget {
  const _DualityItem({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _IconBadge(
              icon: _iconForLabel(label),
              size: 11,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              iconColor: iconColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.bodyText,
                    fontSize: 13.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainList extends StatelessWidget {
  const _PlainList({
    required this.items,
    required this.isNumbered,
    this.startIndex = 1,
  });

  final List<String> items;
  final bool isNumbered;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.bodyText,
          fontSize: 15.5,
        );
    final numberStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedBrown,
          fontWeight: FontWeight.w600,
          fontSize: 15.5,
        );
    final subItemStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.bodyText,
          fontSize: 14.5,
        );

    // If any sibling has a sublist, bold all top-level items for consistency.
    final hasSublistSibling =
        !isNumbered && items.any((item) => _parseSublist(item) != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          _buildItem(
              context, i, bodyStyle, numberStyle, subItemStyle, hasSublistSibling),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    int i,
    TextStyle? bodyStyle,
    TextStyle? numberStyle,
    TextStyle? subItemStyle,
    bool boldTopLevel,
  ) {
    final parsed = isNumbered ? null : _parseSublist(items[i]);

    if (parsed != null) {
      final (label, subItems) = parsed;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _IconBadge(icon: _iconForLabel(items[i]), size: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: bodyStyle?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var si = 0; si < subItems.length; si++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${si + 1}.',
                              style: subItemStyle?.copyWith(
                                color: AppColors.mutedBrown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(subItems[si], style: subItemStyle),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNumbered)
            Text('${startIndex + i}. ', style: numberStyle)
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _IconBadge(icon: _iconForLabel(items[i]), size: 13),
            ),
          if (!isNumbered) const SizedBox(width: 8),
          Expanded(
            child: Text(items[i],
                style: boldTopLevel
                    ? bodyStyle?.copyWith(fontWeight: FontWeight.w600)
                    : bodyStyle),
          ),
        ],
      ),
    );
  }
}

/// Scans blocks for subset-title + sense-list-subset patterns and builds
/// a map from lowercase classification title → list of (element, category).
Map<String, List<(String, _TriadCategory)>> _buildClassificationIconMap(
    List<GatewayRichBlock> blocks) {
  final map = <String, List<(String, _TriadCategory)>>{};
  const categories = [
    _TriadCategory.faculties,
    _TriadCategory.objects,
    _TriadCategory.consciousnesses,
  ];
  for (var i = 0; i < blocks.length; i++) {
    if (blocks[i].type == 'p' && blocks[i].styleClass == 'subset-title') {
      final title = (blocks[i].text ?? '').toLowerCase();
      final activeElements = <(String, _TriadCategory)>[];
      var catIndex = 0;
      for (var j = i + 1;
          j < blocks.length &&
              blocks[j].type == 'ul' &&
              blocks[j].styleClass == 'sense-list-subset';
          j++) {
        final cat = catIndex < categories.length
            ? categories[catIndex]
            : _TriadCategory.consciousnesses;
        for (final item in blocks[j].items) {
          if (!item.startsWith('~')) {
            activeElements.add((item, cat));
          }
        }
        catIndex++;
      }
      map[title] = activeElements;
    }
  }
  return map;
}

class _ClassificationSummaryList extends StatelessWidget {
  const _ClassificationSummaryList({
    required this.items,
    required this.classificationIcons,
  });

  final List<String> items;
  final Map<String, List<(String, _TriadCategory)>> classificationIcons;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.bodyText,
          fontSize: 15.5,
        );
    final labelStyle = bodyStyle?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            _buildItem(context, item, bodyStyle, labelStyle),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String item,
    TextStyle? bodyStyle,
    TextStyle? labelStyle,
  ) {
    final colonIndex = item.indexOf(':');
    final label =
        colonIndex > 0 ? item.substring(0, colonIndex + 1) : item;
    final description =
        colonIndex > 0 ? item.substring(colonIndex + 1).trim() : '';
    final classKey = colonIndex > 0
        ? item.substring(0, colonIndex).trim().toLowerCase()
        : item.toLowerCase();

    final activeElements = classificationIcons[classKey] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _IconBadge(icon: _iconForLabel(label), size: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label, style: labelStyle),
                      if (description.isNotEmpty)
                        TextSpan(text: ' $description', style: bodyStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (activeElements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 33, top: 4),
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (final (element, category) in activeElements)
                    Tooltip(
                      message: element,
                      child: _IconBadge(
                        icon: _iconForLabel(element),
                        size: 11,
                        backgroundColor: category.background,
                        borderColor: category.border,
                        iconColor: category.icon,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.size,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.opacity = 1.0,
  });

  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.white;
    final bd = borderColor ?? const Color(0xFFE6D8C3);
    final ic = iconColor ?? AppColors.primary;
    return Container(
      width: size + 10,
      height: size + 10,
      decoration: BoxDecoration(
        color: opacity < 1.0 ? bg.withValues(alpha: opacity) : bg,
        borderRadius: BorderRadius.circular((size + 10) / 3),
        border: Border.all(
            color: opacity < 1.0 ? bd.withValues(alpha: opacity) : bd),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size,
        color: opacity < 1.0 ? ic.withValues(alpha: opacity) : ic,
      ),
    );
  }
}

/// Parses an item like "4 primary elements: earth, water, fire, wind."
/// into a (label, subItems) pair for rendering as a sublist.
/// Returns null if the item doesn't match the pattern.
(String, List<String>)? _parseSublist(String item) {
  final colonIndex = item.indexOf(':');
  if (colonIndex < 0 || colonIndex >= item.length - 1) return null;

  final label = item.substring(0, colonIndex + 1).trim();
  final remainder = item.substring(colonIndex + 1).trim();

  // Split by commas and semicolons
  final parts =
      remainder.split(RegExp(r'[,;]')).map((p) => p.trim()).toList();
  if (parts.length < 2) return null;

  final subItems = <String>[];
  for (final part in parts) {
    var p = part.trim();
    if (p.isEmpty) continue;
    // Handle "and X" prefix
    if (p.startsWith('and ')) {
      p = p.substring(4);
    }
    // Remove trailing period
    if (p.endsWith('.')) {
      p = p.substring(0, p.length - 1);
    }
    // Capitalize first letter
    if (p.isNotEmpty) {
      p = p[0].toUpperCase() + p.substring(1);
      subItems.add(p);
    }
  }

  if (subItems.length < 2) return null;
  return (label, subItems);
}

List<_TopicAnchor> _buildTopicAnchors(GatewayRichChapter chapter) {
  return [
    for (var i = 0; i < chapter.topics.length; i++)
      _TopicAnchor(
        topic: chapter.topics[i],
        key: GlobalKey(debugLabel: 'gateway-topic-${chapter.number}-$i'),
      ),
  ];
}

Map<String, GlobalKey> _buildTopicLookup(List<_TopicAnchor> anchors) {
  final lookup = <String, GlobalKey>{};
  for (final anchor in anchors) {
    _registerTopicAlias(lookup, anchor.topic.title, anchor.key);
    final title = anchor.topic.title.trim();
    const aggregatePrefix = 'aggregate of ';
    if (title.toLowerCase().startsWith(aggregatePrefix)) {
      final base = title.substring(aggregatePrefix.length).trim();
      _registerTopicAlias(lookup, base, anchor.key);
      if (base.endsWith('s') && base.length > 1) {
        _registerTopicAlias(
            lookup, base.substring(0, base.length - 1), anchor.key);
      } else {
        _registerTopicAlias(lookup, '${base}s', anchor.key);
      }
    }
  }
  return lookup;
}

void _registerTopicAlias(
    Map<String, GlobalKey> lookup, String label, GlobalKey key) {
  final normalized = _normalizeTopicLabel(label);
  if (normalized.isEmpty) return;
  lookup.putIfAbsent(normalized, () => key);
}

GlobalKey? _resolveTopicKey(String label, Map<String, GlobalKey> topicLookup) {
  final direct = topicLookup[_normalizeTopicLabel(label)];
  if (direct != null) return direct;

  final aggregate = topicLookup[_normalizeTopicLabel('Aggregate of $label')];
  if (aggregate != null) return aggregate;

  if (label.endsWith('s') && label.length > 1) {
    final singular = label.substring(0, label.length - 1);
    final singularKey = topicLookup[_normalizeTopicLabel(singular)] ??
        topicLookup[_normalizeTopicLabel('Aggregate of $singular')];
    if (singularKey != null) return singularKey;
  } else {
    final plural = '${label}s';
    final pluralKey = topicLookup[_normalizeTopicLabel(plural)] ??
        topicLookup[_normalizeTopicLabel('Aggregate of $plural')];
    if (pluralKey != null) return pluralKey;
  }

  return null;
}

String _normalizeTopicLabel(String input) {
  return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

final _iconCache = <String, IconData>{};

IconData _iconForLabel(String text) {
  final cached = _iconCache[text];
  if (cached != null) return cached;
  final result = _computeIcon(text);
  _iconCache[text] = result;
  return result;
}

IconData _computeIcon(String text) {
  var t = text.toLowerCase();
  // Strip leading "the " for titles like "The Aggregate of Forms"
  if (t.startsWith('the ')) t = t.substring(4);
  // Skandha (aggregate) patterns – checked first so "Aggregate of Form"
  // doesn't fall through to the generic 'aggregate' → list-bullet icon.
  if (t == 'form' || t == 'forms' || t == 'aggregate of form' ||
      t == 'aggregate of forms') {
    return Icons.category_outlined;
  }
  if (t == 'sensation' || t == 'aggregate of sensation') {
    return Icons.sensors_outlined;
  }
  if (t.startsWith('perceptions') || t == 'aggregate of perceptions') {
    return Icons.remove_red_eye_outlined;
  }
  if (t == 'formations' || t == 'aggregate of formations') {
    return Icons.settings_outlined;
  }
  if (t == 'consciousness' || t == 'aggregate of consciousness') {
    return Icons.psychology_outlined;
  }
  if (t == 'five aggregates') return Icons.format_list_bulleted;
  // Dhatu / sense patterns
  if (t.contains('eye') || t.contains('visual')) {
    return Icons.visibility_outlined;
  }
  if (t.contains('ear') || t.contains('sound')) return Icons.hearing_outlined;
  if (t.contains('nose') || t.contains('smell')) return Icons.air_outlined;
  if (t.contains('tongue') || t.contains('taste')) {
    return Icons.water_drop_outlined;
  }
  if (t.contains('body') || t.contains('texture') || t.contains('touch')) {
    return Icons.pan_tool_outlined;
  }
  if (t.contains('mind') || t.contains('conscious')) {
    return Icons.psychology_outlined;
  }
  if (t.contains('earth')) return Icons.landscape_outlined;
  if (t.contains('water')) return Icons.water_outlined;
  if (t.contains('fire')) return Icons.local_fire_department_outlined;
  if (t.contains('wind')) return Icons.air_outlined;
  if (t.contains('space')) return Icons.public_outlined;
  if (t.contains('time')) return Icons.schedule_outlined;
  if (t.contains('seed')) return Icons.eco_outlined;
  if (t.contains('sprout')) return Icons.spa_outlined;
  if (t.contains('flower') || t.contains('bud') || t.contains('fruit')) {
    return Icons.local_florist_outlined;
  }
  if (t.contains('chapter')) return Icons.menu_book_outlined;
  if (t.contains('table') || t.contains('reference')) {
    return Icons.table_chart_outlined;
  }
  if (t.contains('link') || t.contains('dependent')) return Icons.link_outlined;
  if (t.contains('list') || t.contains('aggregate')) {
    return Icons.format_list_bulleted;
  }
  // Element-classification patterns
  if (t.contains('physical') || t.contains('matter')) {
    return Icons.widgets_outlined;
  }
  if (t.contains('obstruct')) return Icons.block_outlined;
  if (t.contains('undefil')) return Icons.auto_awesome_outlined;
  if (t.contains('realm')) return Icons.layers_outlined;
  if (t.contains('outer')) return Icons.open_in_new_outlined;
  if (t.contains('focus')) return Icons.center_focus_strong_outlined;
  if (t.contains('concept')) return Icons.lightbulb_outlined;
  if (t.contains('sensation')) return Icons.sensors_outlined;
  if (t.contains('perception')) return Icons.remove_red_eye_outlined;
  if (t.contains('formation')) return Icons.settings_outlined;
  // Topic-level patterns
  if (t.contains('classif') || t.contains('categor')) {
    return Icons.category_outlined;
  }
  if (t.contains('triad') || t.contains('dhatu')) {
    return Icons.account_tree_outlined;
  }
  if (t.contains('source') || t.contains('ayatana')) {
    return Icons.swap_horiz_outlined;
  }
  if (t.contains('mental')) return Icons.psychology_outlined;
  if (t.contains('person')) return Icons.person_outline;
  if (t.contains('knowable')) return Icons.school_outlined;
  if (t.contains('cause')) return Icons.device_hub_outlined;
  if (t.contains('condition')) return Icons.tune_outlined;
  if (t.contains('subdivision')) return Icons.vertical_split_outlined;
  if (t.contains('inner')) return Icons.adjust_outlined;
  if (t.contains('element')) return Icons.grain_outlined;
  return Icons.circle_outlined;
}

// ── Skandha (aggregate) colours ──────────────────────────────────────────
const _skandhaIconColor = Color(0xFFB85450);
const _skandhaBadgeBg = Color(0xFFFFF0EF);
const _skandhaBadgeBorder = Color(0xFFE0B4B1);
const _skandhaChipBg = Color(0xFFFFF5F4);
const _skandhaChipBorder = Color(0xFFE8C4C2);

// Ayatana (sense source) colours – teal-green for inner/outer duality
const _ayatanaInnerIcon = Color(0xFF4A7C6F);
const _ayatanaInnerBg = Color(0xFFEDF6F3);
const _ayatanaInnerBorder = Color(0xFFB8D8CC);
const _ayatanaOuterIcon = Color(0xFF5B7BA5);
const _ayatanaOuterBg = Color(0xFFEEF3F9);
const _ayatanaOuterBorder = Color(0xFFB8CCE0);

bool _isSkandhaLabel(String text) {
  var t = text.toLowerCase().trim();
  if (t.startsWith('the ')) t = t.substring(4);
  if (t.startsWith('aggregate of ')) t = t.substring(13);
  // Normalize plurals: "forms" → "form"
  const bases = {'form', 'sensation', 'perceptions', 'formations', 'consciousness'};
  if (bases.contains(t) || t == 'forms') return true;
  if (t == 'five aggregates') return true;
  return false;
}

/// Colour tints that distinguish dhatu categories while keeping badge
/// shape and size identical for consistent spacing.
///   • Faculties – warm amber (subtle physical form)
///   • Objects   – neutral/default
///   • Consciousnesses – soft cool-grey
enum _TriadCategory {
  faculties(
    background: Color(0xFFFFF8E1),
    border: Color(0xFFE8D99A),
    icon: Color(0xFFB8960F),
  ),
  objects(
    background: Color(0xFFECF1F9),
    border: Color(0xFFB8C8DC),
    icon: Color(0xFF4A6FA5),
  ),
  consciousnesses(
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE6D8C3),
    icon: null, // uses AppColors.primary
  );

  const _TriadCategory({
    required this.background,
    required this.border,
    this.icon,
  });

  final Color background;
  final Color border;
  final Color? icon;
}
