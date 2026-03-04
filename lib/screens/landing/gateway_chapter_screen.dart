import 'package:flutter/material.dart';

import '../../services/gateway_rich_content_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';
import '../../widgets/dechen_home_action.dart';
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
          actions: const [DechenHomeAction()],
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
                cacheExtent: 9999,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                children: [
                  _ChapterIntroCard(
                    chapter: chapter,
                    topics: topicAnchors.map((anchor) => anchor.topic).toList(),
                    onOpenTopic: (label) {
                      openTopic(label);
                    },
                    canOpenTopic: canOpenTopic,
                  ),
                  const SizedBox(height: 8),
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
      if (block.type == 'ul' && block.styleClass == 'classification-summary') {
        final classMap = _buildClassificationIconMap(blocks);
        children.add(
          _ClassificationSummaryList(
            items: block.items,
            classificationIcons: classMap,
          ),
        );
        continue;
      }
      if (block.type == 'classification-matrix') {
        children
            .add(const RepaintBoundary(child: _ClassificationOverlapsView()));
        continue;
      }
      children.add(_GatewayBlockView(block: block));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(
                  icon: _iconForLabel(topic.title),
                  size: 15,
                  backgroundColor:
                      _isSkandhaLabel(topic.title) ? _skandhaBadgeBg : null,
                  borderColor:
                      _isSkandhaLabel(topic.title) ? _skandhaBadgeBorder : null,
                  iconColor:
                      _isSkandhaLabel(topic.title) ? _skandhaIconColor : null,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ) ??
                        const TextStyle(
                          fontFamily: 'Crimson Text',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 3),
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
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E0),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFDDD0B8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBadge(icon: _iconForLabel(block.text ?? ''), size: 12),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    block.text ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.bodyText,
                          fontSize: 12.5,
                        ),
                  ),
                ),
              ],
            ),
          );
        }
        if (block.styleClass == 'callout') {
          return Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2DA),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              block.text ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.bodyText,
                    fontSize: 13.5,
                  ),
            ),
          );
        }
        if (block.styleClass == 'topic-copy') {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              block.text ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.bodyText,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
            ),
          );
        }
        if (block.styleClass == 'subset-title') {
          final subTitle = block.text ?? '';
          final isSkandha = _isSkandhaLabel(subTitle);
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 1),
            child: Row(
              children: [
                _IconBadge(
                  icon: _iconForLabel(subTitle),
                  size: 12,
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
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            block.text ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                ),
          ),
        );
      case 'ul':
      case 'ol':
        final isNumbered = block.type == 'ol';
        final items = block.items;
        if (block.styleClass == 'consciousness-stack') {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 2),
                  _ConsciousnessStackItem(label: items[i]),
                ],
              ],
            ),
          );
        }
        if (block.styleClass == 'icon-list-grid' ||
            block.styleClass == 'links-grid') {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 150, maxWidth: 280),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0D3BF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (block.styleClass == 'links-grid')
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8EC),
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: const Color(0xFFCFBDA0)),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.mutedBrown,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          )
                        else
                          _IconBadge(icon: _iconForLabel(items[i]), size: 11),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            items[i],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.bodyText,
                                  fontSize: 13,
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
        if (block.styleClass == 'links-compact') {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0D3BF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8EC),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFCFBDA0)),
                          ),
                          child: Text(
                            '${i + 1}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedBrown,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: _CompactColonItemText(text: items[i]),
                        ),
                      ],
                    ),
                  ),
                ],
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
        if (block.styleClass == 'inner-list') {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _PlainList(
              items: items,
              isNumbered: isNumbered,
              iconSize: 11,
              nestedIconSize: 9,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _PlainList(items: items, isNumbered: isNumbered),
        );
      case 'table':
        if (block.styleClass == 'ayatana-dhatu-map') {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: _AyatanaDhatuMapView(
              headers: block.headers,
              rows: block.rows,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 5),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(color: AppColors.borderLight),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF4E8D5)),
                  children: [
                    for (final header in block.headers)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          header,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                    fontSize: 13,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Text(
                            i < row.length ? row[i] : '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.bodyText,
                                  fontSize: 13,
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

class _CompactColonItemText extends StatelessWidget {
  const _CompactColonItemText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.bodyText,
          fontSize: 12,
          height: 1.3,
        );
    final colonIndex = text.indexOf(':');
    if (colonIndex <= 0 || colonIndex >= text.length - 1) {
      return Text(text, style: baseStyle);
    }
    final lead = text.substring(0, colonIndex + 1);
    final tail = text.substring(colonIndex + 1);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: lead,
            style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: tail),
        ],
      ),
    );
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
        spacing: 5,
        runSpacing: 5,
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
          fontSize: 13,
          decoration: enabled ? TextDecoration.underline : TextDecoration.none,
          fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
        );
    final isSkandha = _isSkandhaLabel(label);
    final chipBg = isSkandha ? _skandhaChipBg : const Color(0xFFFFF5E4);
    final chipBorder = isSkandha ? _skandhaChipBorder : const Color(0xFFDDCEB8);
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(
            icon: _iconForLabel(label),
            size: 11,
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
              color: isSkandha ? _skandhaChipBorder : const Color(0xFFD6C5AB)),
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
      padding: const EdgeInsets.only(top: 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final oneColumn = constraints.maxWidth < 860;
          if (oneColumn) {
            return Column(
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
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
                        EdgeInsets.only(right: i == columns.length - 1 ? 0 : 5),
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
          fontSize: 12.5,
        );
    final disabledItemStyle = itemStyle?.copyWith(
      color: AppColors.bodyText.withValues(alpha: 0.18),
    );
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0D3BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: _iconForLabel(title),
                size: 11,
                backgroundColor: category?.background,
                borderColor: category?.border,
                iconColor: category?.icon,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) {
              final isDisabled = item.startsWith('~');
              final displayItem = isDisabled ? item.substring(1) : item;
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconBadge(
                      icon: _iconForLabel(displayItem),
                      size: 10,
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
    const sideGap = 8.0;
    const centerSpan = sideGap;
    const maxLaneWidth = _compactMapMaxLaneWidth;
    final pairs = <(String, String)>[];
    final count = innerItems.length < outerItems.length
        ? innerItems.length
        : outerItems.length;
    for (var i = 0; i < count; i++) {
      pairs.add((innerItems[i], outerItems[i]));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          final compact = available < 860;
          final laneWidth = compact
              ? ((available - centerSpan) / 2).clamp(120.0, 420.0)
              : ((available - centerSpan) / 2).clamp(120.0, maxLaneWidth);
          final contentWidth = (laneWidth * 2) + centerSpan;

          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: laneWidth,
                        child: _DualityMapPanel(
                          label: 'Inner Sources',
                          icon: Icons.adjust_outlined,
                          color: _ayatanaInnerIcon,
                          items: pairs.map((p) => p.$1).toList(),
                          itemColor: _ayatanaInnerIcon,
                          itemBackgroundColor: _ayatanaInnerBg,
                          itemBorderColor: _ayatanaInnerBorder,
                        ),
                      ),
                      const SizedBox(width: sideGap),
                      SizedBox(
                        width: laneWidth,
                        child: _DualityMapPanel(
                          label: 'Outer Sources',
                          icon: Icons.open_in_new_outlined,
                          color: _ayatanaOuterIcon,
                          items: pairs.map((p) => p.$2).toList(),
                          itemColor: _ayatanaOuterIcon,
                          itemBackgroundColor: _ayatanaOuterBg,
                          itemBorderColor: _ayatanaOuterBorder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DualityMapPanel extends StatelessWidget {
  const _DualityMapPanel({
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
    required this.itemColor,
    required this.itemBackgroundColor,
    required this.itemBorderColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final List<String> items;
  final Color itemColor;
  final Color itemBackgroundColor;
  final Color itemBorderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_compactMapPanelPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0D3BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _compactMapTitleHeight,
            child: Row(
              children: [
                _IconBadge(
                  icon: icon,
                  size: _compactMapHeaderIconSize,
                  backgroundColor: itemBackgroundColor,
                  borderColor: itemBorderColor,
                  iconColor: color,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: _compactMapTitleFontSize,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _compactMapHeaderBottomSpacing),
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: EdgeInsets.only(
                bottom: i == items.length - 1 ? 0 : _compactMapRowSpacing,
              ),
              child: _DualityMapNode(
                label: items[i],
                color: itemColor,
                backgroundColor: itemBackgroundColor,
                borderColor: itemBorderColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DualityMapNode extends StatelessWidget {
  const _DualityMapNode({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBadge(
          icon: _iconForLabel(label),
          size: _compactMapItemIconSize,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          iconColor: color,
        ),
        const SizedBox(width: _compactMapItemGap),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.bodyText,
                  fontSize: _compactMapItemFontSize,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
      ],
    );
  }
}

/// Identity connector: ayatana corresponds to / equals a dhatu.
/// Shows an equals sign (≡) indicating structural equivalence.
class _IdentityConnector extends StatelessWidget {
  const _IdentityConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Center(
        child: Text(
          '≡',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.mutedBrown.withValues(alpha: 0.65),
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// One-to-many brace connector used for Mind Source → 7 dhatus.
class _OneToManyBraceConnector extends StatelessWidget {
  const _OneToManyBraceConnector({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.mutedBrown.withValues(alpha: 0.7);
    return SizedBox(
      width: 14,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(14, height),
            painter: _BracePainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _BracePainter extends CustomPainter {
  const _BracePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final x = w * 0.82;
    final inner = w * 0.32;
    final mid = h * 0.5;
    final path = Path()
      ..moveTo(x, 0)
      ..quadraticBezierTo(inner, 0, inner, h * 0.20)
      ..quadraticBezierTo(inner, h * 0.36, w * 0.08, mid - 1)
      ..quadraticBezierTo(inner, mid, inner, h * 0.64)
      ..quadraticBezierTo(inner, h * 0.80, x, h);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BracePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _AyatanaDhatuMapView extends StatelessWidget {
  const _AyatanaDhatuMapView({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    const connectorSpan = 18.0; // 2 + 14 + 2
    const maxLaneWidth = _compactMapMaxLaneWidth;
    final leftHeader = headers.isNotEmpty ? headers.first : '12 Ayatanas';
    final rightHeader = headers.length > 1 ? headers[1] : '18 Dhatus';

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDCDB6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth;
              final compact = available < 860;
              final laneWidth = compact
                  ? ((available - connectorSpan) / 2).clamp(120.0, 420.0)
                  : ((available - connectorSpan) / 2)
                      .clamp(120.0, maxLaneWidth);
              final contentWidth = (laneWidth * 2) + connectorSpan;
              return Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: laneWidth,
                            child: _AyatanaMapHeadChip(
                              label: leftHeader,
                              icon: Icons.account_tree_outlined,
                              color: _ayatanaInnerIcon,
                            ),
                          ),
                          const SizedBox(width: connectorSpan),
                          SizedBox(
                            width: laneWidth,
                            child: _AyatanaMapHeadChip(
                              label: rightHeader,
                              icon: Icons.widgets_outlined,
                              color: _ayatanaOuterIcon,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _compactMapHeaderBottomSpacing),
                      ...rows.where((r) => r.length >= 2).map((r) {
                        final left = r[0];
                        final right = r[1];
                        final mindRow =
                            left.toLowerCase().contains('mind source');
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: _compactMapRowSpacing,
                          ),
                          child: _AyatanaMapRow(
                            leftLabel: left,
                            rightLabel: right,
                            isMindRow: mindRow,
                            laneWidth: laneWidth,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AyatanaMapHeadChip extends StatelessWidget {
  const _AyatanaMapHeadChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _compactMapTitleHeight,
      child: Row(
        children: [
          _IconBadge(
            icon: icon,
            size: _compactMapHeaderIconSize,
            backgroundColor: color.withValues(alpha: 0.1),
            borderColor: color.withValues(alpha: 0.35),
            iconColor: color,
          ),
          const SizedBox(width: _compactMapHeaderGap),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: _compactMapTitleFontSize,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyatanaMapRow extends StatelessWidget {
  const _AyatanaMapRow({
    required this.leftLabel,
    required this.rightLabel,
    required this.isMindRow,
    required this.laneWidth,
  });

  final String leftLabel;
  final String rightLabel;
  final bool isMindRow;
  final double laneWidth;

  @override
  Widget build(BuildContext context) {
    final dhatuCategory = _dhatuCategoryForLabel(rightLabel);
    final sourceStyle = _ayatanaSourceStyleForLabel(leftLabel);
    if (isMindRow) {
      return _buildMindRow(context);
    }

    return Row(
      children: [
        SizedBox(
          width: laneWidth,
          child: _AyatanaMapNode(
            label: leftLabel,
            tint: sourceStyle.background,
            border: sourceStyle.border,
            iconColor: sourceStyle.icon,
          ),
        ),
        const SizedBox(width: 2),
        const _IdentityConnector(),
        const SizedBox(width: 2),
        SizedBox(
          width: laneWidth,
          child: _AyatanaMapNode(
            label: rightLabel,
            tint: dhatuCategory?.background ?? _ayatanaOuterBg,
            border: dhatuCategory?.border ?? _ayatanaOuterBorder,
            iconColor: dhatuCategory?.icon ?? _ayatanaOuterIcon,
            dhatuCategory: dhatuCategory,
          ),
        ),
      ],
    );
  }

  /// Builds the Mind Source row with 7 separate bars on the right:
  /// 1 × Mind Element (faculty yellow) + 6 × consciousness elements (white).
  Widget _buildMindRow(BuildContext context) {
    const mindBars = <({String label, IconData icon, _TriadCategory cat})>[
      (
        label: 'Mind Element',
        icon: Icons.psychology_outlined,
        cat: _TriadCategory.faculties,
      ),
      (
        label: 'Eye Consciousness Element',
        icon: Icons.visibility_outlined,
        cat: _TriadCategory.consciousnesses,
      ),
      (
        label: 'Ear Consciousness Element',
        icon: Icons.hearing_outlined,
        cat: _TriadCategory.consciousnesses,
      ),
      (
        label: 'Nose Consciousness Element',
        icon: Icons.air_outlined,
        cat: _TriadCategory.consciousnesses,
      ),
      (
        label: 'Tongue Consciousness Element',
        icon: Icons.water_drop_outlined,
        cat: _TriadCategory.consciousnesses,
      ),
      (
        label: 'Body Consciousness Element',
        icon: Icons.pan_tool_outlined,
        cat: _TriadCategory.consciousnesses,
      ),
      (
        label: 'Mind Consciousness Element',
        icon: Icons.psychology_outlined,
        cat: _TriadCategory.consciousnesses,
      ),
    ];

    Widget buildRightBars() {
      return Column(
        children: [
          for (var i = 0; i < mindBars.length; i++) ...[
            if (i > 0)
              const SizedBox(
                height: _compactMapRowSpacing,
              ),
            _AyatanaMapNode(
              label: mindBars[i].label,
              tint: mindBars[i].cat.background,
              border: mindBars[i].cat.border,
              iconColor: mindBars[i].cat.icon ?? AppColors.primary,
              dhatuCategory: mindBars[i].cat,
              fixedHeight: _compactMapMindRowHeight,
            ),
          ],
        ],
      );
    }

    const rowCount = 7;
    const rowHeight = _compactMapMindRowHeight;
    const rowGap = _compactMapRowSpacing;
    const braceHeight = (rowCount * rowHeight) + ((rowCount - 1) * rowGap);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: laneWidth,
          child: SizedBox(
            height: braceHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _AyatanaMapNode(
                label: leftLabel,
                tint: _ayatanaInnerBg,
                border: _ayatanaInnerBorder,
                iconColor: _ayatanaInnerIcon,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        const _OneToManyBraceConnector(height: braceHeight),
        const SizedBox(width: 2),
        SizedBox(width: laneWidth, child: buildRightBars()),
      ],
    );
  }
}

_AyatanaSourceStyle _ayatanaSourceStyleForLabel(String label) {
  final t = label.toLowerCase();
  if (t.contains('object source')) {
    return const _AyatanaSourceStyle(
      background: _ayatanaOuterBg,
      border: _ayatanaOuterBorder,
      icon: _ayatanaOuterIcon,
    );
  }
  return const _AyatanaSourceStyle(
    background: _ayatanaInnerBg,
    border: _ayatanaInnerBorder,
    icon: _ayatanaInnerIcon,
  );
}

class _AyatanaSourceStyle {
  const _AyatanaSourceStyle({
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color icon;
}

class _AyatanaMapNode extends StatelessWidget {
  const _AyatanaMapNode({
    required this.label,
    required this.tint,
    required this.border,
    required this.iconColor,
    this.dhatuCategory,
    this.fixedHeight,
  });

  final String label;
  final Color tint;
  final Color border;
  final Color iconColor;
  final _TriadCategory? dhatuCategory;
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final effectiveTint = dhatuCategory?.background ?? tint;
    final effectiveBorder = dhatuCategory?.border ?? border;
    final effectiveIconColor = dhatuCategory?.icon ??
        (dhatuCategory != null ? AppColors.primary : iconColor);

    final row = Row(
      children: [
        _IconBadge(
          icon: _iconForLabel(label),
          size: _compactMapItemIconSize,
          backgroundColor: effectiveTint,
          borderColor: effectiveBorder,
          iconColor: effectiveIconColor,
        ),
        const SizedBox(width: _compactMapItemGap),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.bodyText,
                  fontSize: _compactMapItemFontSize,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
      ],
    );
    if (fixedHeight == null) return row;
    return SizedBox(height: fixedHeight, child: row);
  }
}

// Shared compact mapping style tokens to keep chapter-3 map sections consistent.
const _compactMapMaxLaneWidth = 210.0;
const _compactMapPanelPadding = 7.0;
const _compactMapTitleHeight = 28.0;
const _compactMapTitleFontSize = 13.0;
const _compactMapHeaderIconSize = 10.0;
const _compactMapHeaderGap = 5.0;
const _compactMapHeaderBottomSpacing = 4.0;
const _compactMapItemIconSize = 10.0;
const _compactMapItemGap = 6.0;
const _compactMapItemFontSize = 12.5;
const _compactMapRowSpacing = 3.0;
const _compactMapMindRowHeight = 24.0;

/// A single plain row for the Aggregate of Consciousness stack.
/// Mind Element gets faculty (yellow) badge; consciousness elements get
/// neutral badges.
class _ConsciousnessStackItem extends StatelessWidget {
  const _ConsciousnessStackItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cat = _dhatuCategoryForLabel(label) ?? _TriadCategory.consciousnesses;
    final iconColor = cat.icon ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBadge(
          icon: _iconForLabel(label),
          size: 12,
          backgroundColor: cat.background,
          borderColor: cat.border,
          iconColor: iconColor,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.bodyText,
                fontSize: 13,
              ),
        ),
      ],
    );
  }
}

_TriadCategory? _dhatuCategoryForLabel(String label) {
  final t = label.toLowerCase();
  if (t.contains('sense-faculty dhatus') ||
      t.contains('sense-faculty dhātus')) {
    return _TriadCategory.faculties;
  }
  if (t.contains('sense-object dhatus') || t.contains('sense-object dhātus')) {
    return _TriadCategory.objects;
  }
  if (RegExp(r'\b(eye|ear|nose|tongue|body|mind) element\b').hasMatch(t)) {
    return _TriadCategory.faculties;
  }
  if (t.contains('visual form element') ||
      t.contains('sound element') ||
      t.contains('smell element') ||
      t.contains('taste element') ||
      t.contains('texture element') ||
      t.contains('mental object element')) {
    return _TriadCategory.objects;
  }
  if (t.contains('consciousness element')) {
    return _TriadCategory.consciousnesses;
  }
  return null;
}

class _PlainList extends StatelessWidget {
  const _PlainList({
    required this.items,
    required this.isNumbered,
    this.startIndex = 1,
    this.iconSize = 13,
    this.nestedIconSize = 11,
  });

  final List<String> items;
  final bool isNumbered;
  final int startIndex;
  final double iconSize;
  final double nestedIconSize;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.bodyText,
          fontSize: 13.5,
        );
    final numberStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedBrown,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        );
    final subItemStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.bodyText,
          fontSize: 12.5,
        );

    // If any sibling has a sublist, bold all top-level items for consistency.
    final hasSublistSibling =
        !isNumbered && items.any((item) => _parseSublist(item) != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          _buildItem(context, i, bodyStyle, numberStyle, subItemStyle,
              hasSublistSibling),
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
                  child: _semanticIconBadge(items[i], size: iconSize),
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
                          _semanticIconBadge(subItems[si],
                              size: nestedIconSize),
                          const SizedBox(width: 6),
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
              child: _semanticIconBadge(items[i], size: iconSize),
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

Widget _semanticIconBadge(String label, {required double size}) {
  final t = label.toLowerCase();

  if (t.contains('physical or verbal action')) {
    return _IconBadge(
      icon: Icons.directions_run,
      size: size,
      backgroundColor: _skandhaBadgeBg,
      borderColor: _skandhaBadgeBorder,
      iconColor: _skandhaIconColor,
    );
  }

  if (t.contains('five sense-faculty dhatus') ||
      t.contains('five sense-faculty dhātus')) {
    return _fiveDhatuStrip(_TriadCategory.faculties, size: size);
  }
  if (t.contains('five sense-object dhatus') ||
      t.contains('five sense-object dhātus')) {
    return _fiveDhatuStrip(_TriadCategory.objects, size: size);
  }

  // Keep all imperceptible-form variants visually unified across chapter 1.
  if (t.contains('imperceptible form')) {
    return _IconBadge(
      icon: _iconForLabel(label),
      size: size,
      backgroundColor: _skandhaBadgeBg,
      borderColor: _skandhaBadgeBorder,
      iconColor: _skandhaIconColor,
    );
  }

  // Reuse chapter-2 dhatu category colours when a label points to dhatus.
  final cat = _dhatuCategoryForLabel(label);
  if (cat != null) {
    return _IconBadge(
      icon: _iconForLabel(label),
      size: size,
      backgroundColor: cat.background,
      borderColor: cat.border,
      iconColor: cat.icon ?? AppColors.primary,
    );
  }

  // Keep form-type labels in the same pink family as Aggregate of Form.
  if (t.contains(' form') || t.startsWith('form ')) {
    return _IconBadge(
      icon: _iconForLabel(label),
      size: size,
      backgroundColor: _skandhaBadgeBg,
      borderColor: _skandhaBadgeBorder,
      iconColor: _skandhaIconColor,
    );
  }

  return _IconBadge(icon: _iconForLabel(label), size: size);
}

Widget _fiveDhatuStrip(_TriadCategory category, {required double size}) {
  const icons = <IconData>[
    Icons.visibility_outlined,
    Icons.hearing_outlined,
    Icons.air_outlined,
    Icons.water_drop_outlined,
    Icons.pan_tool_outlined,
  ];

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < icons.length; i++) ...[
        if (i > 0) const SizedBox(width: 2),
        _IconBadge(
          icon: icons[i],
          size: size,
          backgroundColor: category.background,
          borderColor: category.border,
          iconColor: category.icon ?? AppColors.primary,
        ),
      ],
    ],
  );
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
          fontSize: 13.5,
        );
    final labelStyle = bodyStyle?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
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
    final label = colonIndex > 0 ? item.substring(0, colonIndex + 1) : item;
    final description =
        colonIndex > 0 ? item.substring(colonIndex + 1).trim() : '';
    final classKey = colonIndex > 0
        ? item.substring(0, colonIndex).trim().toLowerCase()
        : item.toLowerCase();

    final activeElements = classificationIcons[classKey] ?? [];
    final activeNames =
        activeElements.map((e) => e.$1.toLowerCase().trim()).toSet();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _IconBadge(icon: _iconForLabel(label), size: 11),
              ),
              const SizedBox(width: 6),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var g = 0; g < _kClassificationGroups.length; g++) ...[
                    _buildClassificationColumn(
                      context,
                      _kClassificationGroups[g],
                      activeNames,
                    ),
                    if (g < _kClassificationGroups.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassificationColumn(
    BuildContext context,
    _ClassificationGroup group,
    Set<String> activeNames,
  ) {
    return Column(
      children: [
        for (var i = 0; i < group.elements.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          _buildElementIconCell(
            context,
            group.elements[i],
            group.category,
            activeNames.contains(group.elements[i].toLowerCase()),
          ),
        ],
      ],
    );
  }

  Widget _buildElementIconCell(
    BuildContext context,
    String element,
    _TriadCategory category,
    bool enabled,
  ) {
    final iconColor = category.icon ?? AppColors.primary;
    final fg =
        enabled ? iconColor : AppColors.mutedBrown.withValues(alpha: 0.45);
    return _IconBadge(
      icon: _iconForLabel(element),
      size: 11,
      backgroundColor: enabled ? category.background : const Color(0xFFF2ECE3),
      borderColor: enabled ? category.border : const Color(0xFFD9CCB8),
      iconColor: fg,
    );
  }
}

class _ClassificationGroup {
  const _ClassificationGroup(this.category, this.elements);
  final _TriadCategory category;
  final List<String> elements;
}

const _kClassificationGroups = <_ClassificationGroup>[
  _ClassificationGroup(
    _TriadCategory.faculties,
    <String>[
      'Eye Element',
      'Ear Element',
      'Nose Element',
      'Tongue Element',
      'Body Element',
      'Mind Element',
    ],
  ),
  _ClassificationGroup(
    _TriadCategory.objects,
    <String>[
      'Visual Form Element',
      'Sound Element',
      'Smell Element',
      'Taste Element',
      'Texture Element',
      'Mental Object Element',
    ],
  ),
  _ClassificationGroup(
    _TriadCategory.consciousnesses,
    <String>[
      'Eye Consciousness Element',
      'Ear Consciousness Element',
      'Nose Consciousness Element',
      'Tongue Consciousness Element',
      'Body Consciousness Element',
      'Mind Consciousness Element',
    ],
  ),
];

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
    final bd = borderColor ?? const Color(0xFFD6C5AA);
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
  final parts = remainder.split(RegExp(r'[,;]')).map((p) => p.trim()).toList();
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
  if (t == 'form' ||
      t == 'forms' ||
      t == 'aggregate of form' ||
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
  // Chapter 1: five forms of mental objects.
  if (t.contains('deduced form')) return Icons.manage_search_outlined;
  if (t.contains('spatial form')) return Icons.crop_free_outlined;
  if (t.contains('imperceptible form')) return Icons.visibility_off_outlined;
  if (t.contains('imagined form')) return Icons.lightbulb_outline;
  if (t.contains('mastered form') || t.contains('through meditation')) {
    return Icons.self_improvement_outlined;
  }
  if (t.contains('sense-faculty dhatus') ||
      t.contains('sense-faculty dhātus')) {
    return Icons.pan_tool_outlined;
  }
  if (t.contains('sense-object dhatus') || t.contains('sense-object dhātus')) {
    return Icons.visibility_outlined;
  }
  if ((t.contains('sense faculties') && t.contains('sense objects')) ||
      (t.contains('sense-faculty dhatus') &&
          t.contains('sense-object dhatus')) ||
      (t.contains('sense-faculty dhātus') &&
          t.contains('sense-object dhātus'))) {
    return Icons.account_tree_outlined;
  }
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

// ── Skandha (aggregate) colours – rich reds ─────────────────────────────
const _skandhaIconColor = Color(0xFF5A2D6B);
const _skandhaBadgeBg = Color(0xFFEDE3F2);
const _skandhaBadgeBorder = Color(0xFF8C6AA0);
const _skandhaChipBg = Color(0xFFF2EAF6);
const _skandhaChipBorder = Color(0xFF6E4A83);

// Ayatana (sense source) colours – green for inner, blue for outer
const _ayatanaInnerIcon = Color(0xFF2E7D52);
const _ayatanaInnerBg = Color(0xFFE6F4EC);
const _ayatanaInnerBorder = Color(0xFF88C4A0);
const _ayatanaOuterIcon = Color(0xFF2C5F8A);
const _ayatanaOuterBg = Color(0xFFE4EEF6);
const _ayatanaOuterBorder = Color(0xFF85B0D4);

// ─────────────────────────────────────────────────────────────────────────
// Classification Overlaps – interactive matrix + region cards
// ─────────────────────────────────────────────────────────────────────────

/// One of the 18 dhatus for the overlap matrix.
class _DhatuEntry {
  const _DhatuEntry(this.id, this.name, this.icon, this.triad);
  final String id;
  final String name;
  final IconData icon;
  final _TriadCategory triad;
}

/// One of the 10 classification sets.
class _SetEntry {
  const _SetEntry(this.id, this.name, this.icon);
  final String id;
  final String name;
  final IconData icon;
}

/// An overlap region (group of dhatus with the same membership pattern).
class _OverlapRegion {
  const _OverlapRegion(this.title, this.dhatuIds, this.setIds);
  final String title;
  final List<String> dhatuIds;
  final List<String> setIds;
}

const _kDhatus = <_DhatuEntry>[
  _DhatuEntry('eye-fac', 'Eye Faculty', Icons.visibility_outlined,
      _TriadCategory.faculties),
  _DhatuEntry('ear-fac', 'Ear Faculty', Icons.hearing_outlined,
      _TriadCategory.faculties),
  _DhatuEntry(
      'nose-fac', 'Nose Faculty', Icons.air_outlined, _TriadCategory.faculties),
  _DhatuEntry('tongue-fac', 'Tongue Faculty', Icons.water_drop_outlined,
      _TriadCategory.faculties),
  _DhatuEntry('body-fac', 'Body Faculty', Icons.pan_tool_outlined,
      _TriadCategory.faculties),
  _DhatuEntry('mind-fac', 'Mind Faculty', Icons.psychology_outlined,
      _TriadCategory.faculties),
  _DhatuEntry('visual-obj', 'Visual Form', Icons.visibility_outlined,
      _TriadCategory.objects),
  _DhatuEntry(
      'sound-obj', 'Sound', Icons.hearing_outlined, _TriadCategory.objects),
  _DhatuEntry('smell-obj', 'Smell', Icons.air_outlined, _TriadCategory.objects),
  _DhatuEntry(
      'taste-obj', 'Taste', Icons.water_drop_outlined, _TriadCategory.objects),
  _DhatuEntry('texture-obj', 'Texture', Icons.pan_tool_outlined,
      _TriadCategory.objects),
  _DhatuEntry('mental-obj', 'Mental Object', Icons.psychology_outlined,
      _TriadCategory.objects),
  _DhatuEntry('eye-con', 'Eye Consc.', Icons.visibility_outlined,
      _TriadCategory.consciousnesses),
  _DhatuEntry('ear-con', 'Ear Consc.', Icons.hearing_outlined,
      _TriadCategory.consciousnesses),
  _DhatuEntry('nose-con', 'Nose Consc.', Icons.air_outlined,
      _TriadCategory.consciousnesses),
  _DhatuEntry('tongue-con', 'Tongue Consc.', Icons.water_drop_outlined,
      _TriadCategory.consciousnesses),
  _DhatuEntry('body-con', 'Body Consc.', Icons.pan_tool_outlined,
      _TriadCategory.consciousnesses),
  _DhatuEntry('mind-con', 'Mind Consc.', Icons.psychology_outlined,
      _TriadCategory.consciousnesses),
];

const _kSets = <_SetEntry>[
  _SetEntry('physical-form', 'Physical Form', Icons.widgets_outlined),
  _SetEntry('mut-obstruct', 'Mut. Obstructive', Icons.block_outlined),
  _SetEntry('outer', 'Outer', Icons.open_in_new_outlined),
  _SetEntry('personal-sens', 'Personal Sens.', Icons.person_outline),
  _SetEntry('desire-realm', 'Desire Realm', Icons.layers_outlined),
  _SetEntry('form-realm', 'Form Realm', Icons.layers_outlined),
  _SetEntry('formless-realm', 'Formless Realm', Icons.layers_outlined),
  _SetEntry('undefiling', 'Undefiling', Icons.auto_awesome_outlined),
  _SetEntry('focus', 'Focus', Icons.center_focus_strong_outlined),
  _SetEntry('concepts', 'Concepts', Icons.lightbulb_outlined),
];

/// Membership: dhatu id → set of classification ids it belongs to.
const _kMembership = <String, Set<String>>{
  'eye-fac': {
    'physical-form',
    'mut-obstruct',
    'personal-sens',
    'desire-realm',
    'form-realm'
  },
  'ear-fac': {
    'physical-form',
    'mut-obstruct',
    'personal-sens',
    'desire-realm',
    'form-realm'
  },
  'nose-fac': {
    'physical-form',
    'mut-obstruct',
    'personal-sens',
    'desire-realm'
  },
  'tongue-fac': {
    'physical-form',
    'mut-obstruct',
    'personal-sens',
    'desire-realm'
  },
  'body-fac': {
    'physical-form',
    'mut-obstruct',
    'personal-sens',
    'desire-realm',
    'form-realm'
  },
  'mind-fac': {
    'desire-realm',
    'form-realm',
    'formless-realm',
    'undefiling',
    'focus',
    'concepts'
  },
  'visual-obj': {
    'physical-form',
    'mut-obstruct',
    'outer',
    'desire-realm',
    'form-realm'
  },
  'sound-obj': {
    'physical-form',
    'mut-obstruct',
    'outer',
    'desire-realm',
    'form-realm'
  },
  'smell-obj': {
    'physical-form',
    'mut-obstruct',
    'outer',
    'personal-sens',
    'desire-realm'
  },
  'taste-obj': {
    'physical-form',
    'mut-obstruct',
    'outer',
    'personal-sens',
    'desire-realm'
  },
  'texture-obj': {
    'physical-form',
    'mut-obstruct',
    'outer',
    'personal-sens',
    'desire-realm',
    'form-realm'
  },
  'mental-obj': {
    'physical-form',
    'outer',
    'personal-sens',
    'desire-realm',
    'form-realm',
    'formless-realm',
    'undefiling',
    'focus',
    'concepts'
  },
  'eye-con': {'desire-realm', 'form-realm', 'focus'},
  'ear-con': {'desire-realm', 'form-realm', 'focus'},
  'nose-con': {'desire-realm', 'form-realm', 'focus'},
  'tongue-con': {'desire-realm', 'form-realm', 'focus'},
  'body-con': {'desire-realm', 'form-realm', 'focus'},
  'mind-con': {
    'desire-realm',
    'form-realm',
    'formless-realm',
    'undefiling',
    'focus',
    'concepts'
  },
};

const _kRegions = <_OverlapRegion>[
  _OverlapRegion('Sense Faculties in Form Realm', [
    'eye-fac',
    'ear-fac',
    'body-fac'
  ], [
    'physical-form',
    'mut-obstruct',
    'personal-sens',
    'desire-realm',
    'form-realm'
  ]),
  _OverlapRegion(
      'Sense Faculties not in Form Realm',
      ['nose-fac', 'tongue-fac'],
      ['physical-form', 'mut-obstruct', 'personal-sens', 'desire-realm']),
  _OverlapRegion('Distant Sense Objects', ['visual-obj', 'sound-obj'],
      ['physical-form', 'mut-obstruct', 'outer', 'desire-realm', 'form-realm']),
  _OverlapRegion('Proximate Objects (Desire only)', [
    'smell-obj',
    'taste-obj'
  ], [
    'physical-form',
    'mut-obstruct',
    'outer',
    'personal-sens',
    'desire-realm'
  ]),
  _OverlapRegion('Texture (unique 6-set)', [
    'texture-obj'
  ], [
    'physical-form',
    'mut-obstruct',
    'outer',
    'personal-sens',
    'desire-realm',
    'form-realm'
  ]),
  _OverlapRegion('Mental Object (9 of 10)', [
    'mental-obj'
  ], [
    'physical-form',
    'outer',
    'personal-sens',
    'desire-realm',
    'form-realm',
    'formless-realm',
    'undefiling',
    'focus',
    'concepts'
  ]),
  _OverlapRegion('The Mental Pair', [
    'mind-fac',
    'mind-con'
  ], [
    'desire-realm',
    'form-realm',
    'formless-realm',
    'undefiling',
    'focus',
    'concepts'
  ]),
  _OverlapRegion(
      'Five Sense Consciousnesses',
      ['eye-con', 'ear-con', 'nose-con', 'tongue-con', 'body-con'],
      ['desire-realm', 'form-realm', 'focus']),
];

// Reverse lookup: set id → list of member dhatu ids.
final Map<String, List<String>> _kSetMembers = () {
  final m = <String, List<String>>{};
  for (final s in _kSets) {
    m[s.id] = [
      for (final d in _kDhatus)
        if (_kMembership[d.id]?.contains(s.id) ?? false) d.id,
    ];
  }
  return m;
}();

// Quick lookup maps.
final Map<String, _DhatuEntry> _kDhatuMap = {for (final d in _kDhatus) d.id: d};
final Map<String, _SetEntry> _kSetMap = {for (final s in _kSets) s.id: s};

class _ClassificationOverlapsView extends StatefulWidget {
  const _ClassificationOverlapsView();

  @override
  State<_ClassificationOverlapsView> createState() =>
      _ClassificationOverlapsViewState();
}

class _ClassificationOverlapsViewState
    extends State<_ClassificationOverlapsView> {
  String? _selectedDhatu;
  String? _selectedSet;

  void _tapDhatu(String id) {
    setState(() {
      if (_selectedDhatu == id) {
        _selectedDhatu = null;
      } else {
        _selectedDhatu = id;
        _selectedSet = null;
      }
    });
  }

  void _tapSet(String id) {
    setState(() {
      if (_selectedSet == id) {
        _selectedSet = null;
      } else {
        _selectedSet = id;
        _selectedDhatu = null;
      }
    });
  }

  bool _isDhatuHighlighted(String dhatuId) {
    if (_selectedDhatu != null) return dhatuId == _selectedDhatu;
    if (_selectedSet != null) {
      return _kMembership[dhatuId]?.contains(_selectedSet) ?? false;
    }
    return true; // nothing selected → all visible
  }

  bool _isSetHighlighted(String setId) {
    if (_selectedSet != null) return setId == _selectedSet;
    if (_selectedDhatu != null) {
      return _kMembership[_selectedDhatu]?.contains(setId) ?? false;
    }
    return true;
  }

  bool get _hasSelection => _selectedDhatu != null || _selectedSet != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildMatrix(context),
        _buildInfoSummary(context),
        const SizedBox(height: 16),
        _buildRegionCards(context),
      ],
    );
  }

  // ── Interactive matrix ──

  Widget _buildMatrix(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const SizedBox(width: 120), // row-header spacer
              for (final s in _kSets) _buildColHeader(context, s),
            ],
          ),
          // Dhatu rows
          for (var i = 0; i < _kDhatus.length; i++) ...[
            if (i == 6 || i == 12) // separators between triads
              Container(
                  height: 1,
                  width: 120.0 + _kSets.length * 38,
                  color: AppColors.border),
            _buildRow(context, _kDhatus[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildColHeader(BuildContext context, _SetEntry s) {
    final highlighted = _isSetHighlighted(s.id);
    final active = _selectedSet == s.id;
    return GestureDetector(
      onTap: () => _tapSet(s.id),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _hasSelection && !highlighted ? 0.2 : 1.0,
        child: Container(
          width: 38,
          height: 110,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFF4E8D5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.borderLight,
              width: active ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(s.icon,
                  size: 12,
                  color: active ? Colors.white : AppColors.mutedBrown),
              const SizedBox(height: 2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.mutedBrown,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, _DhatuEntry d) {
    final highlighted = _isDhatuHighlighted(d.id);
    final active = _selectedDhatu == d.id;
    final sets = _kMembership[d.id] ?? const <String>{};

    return GestureDetector(
      onTap: () => _tapDhatu(d.id),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _hasSelection && !highlighted ? 0.2 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: active ? const Color(0x308B7355) : Colors.transparent,
          child: Row(
            children: [
              // Row header
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    _IconBadge(
                      icon: d.icon,
                      size: 11,
                      backgroundColor: d.triad.background,
                      borderColor: d.triad.border,
                      iconColor: d.triad.icon,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        d.name,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: d.triad.icon ?? AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Cells
              for (final s in _kSets)
                _buildCell(sets.contains(s.id), s.id, d.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(bool isMember, String setId, String dhatuId) {
    final setActive = _selectedSet == setId;
    final dhatuActive = _selectedDhatu == dhatuId;
    final cellHighlighted = setActive || dhatuActive;

    return Container(
      width: 38,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isMember && cellHighlighted
            ? const Color(0x40D4A017)
            : isMember
                ? const Color(0xFFFFF8E1)
                : const Color(0xFFFAFAF5),
        border: Border.all(color: AppColors.borderLight, width: 0.3),
      ),
      child: isMember
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: cellHighlighted ? 10 : 7,
              height: cellHighlighted ? 10 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cellHighlighted
                    ? AppColors.primary
                    : const Color(0xFFB8960F),
              ),
            )
          : null,
    );
  }

  // ── Info summary ──

  Widget _buildInfoSummary(BuildContext context) {
    if (!_hasSelection) return const SizedBox(height: 8);

    final String title;
    final String subtitle;
    final List<Widget> tags;

    if (_selectedDhatu != null) {
      final d = _kDhatuMap[_selectedDhatu]!;
      final sets = _kMembership[_selectedDhatu] ?? const <String>{};
      title = d.name;
      subtitle = 'Member of ${sets.length} of 10 classifications';
      tags = [
        for (final sId in _kSets.map((s) => s.id))
          if (sets.contains(sId)) _buildSetPill(_kSetMap[sId]!, true),
      ];
    } else {
      final s = _kSetMap[_selectedSet]!;
      final members = _kSetMembers[_selectedSet] ?? [];
      title = s.name;
      subtitle = 'Contains ${members.length} of 18 dhatus';
      tags = [
        for (final dId in members) _buildDhatuPill(_kDhatuMap[dId]!, true),
      ];
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2DA),
          borderRadius: BorderRadius.circular(9),
          border: Border(
            left: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.7),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedBrown,
                )),
            const SizedBox(height: 6),
            Wrap(spacing: 4, runSpacing: 4, children: tags),
          ],
        ),
      ),
    );
  }

  Widget _buildSetPill(_SetEntry s, bool highlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.cardBeige : AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 10, color: AppColors.mutedBrown),
          const SizedBox(width: 4),
          Text(s.name,
              style:
                  const TextStyle(fontSize: 10.5, color: AppColors.mutedBrown)),
        ],
      ),
    );
  }

  Widget _buildDhatuPill(_DhatuEntry d, bool highlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: d.triad.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: d.triad.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(d.icon, size: 10, color: d.triad.icon ?? AppColors.primary),
          const SizedBox(width: 4),
          Text(d.name,
              style: TextStyle(
                fontSize: 10.5,
                color: d.triad.icon ?? AppColors.primary,
              )),
        ],
      ),
    );
  }

  // ── Region cards ──

  Widget _buildRegionCards(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final r in _kRegions) _buildRegionCard(context, r)],
    );
  }

  Widget _buildRegionCard(BuildContext context, _OverlapRegion region) {
    final hasOverlap =
        !_hasSelection || region.dhatuIds.any((d) => _isDhatuHighlighted(d));

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: hasOverlap ? 1.0 : 0.2,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE0D3BF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(region.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 5),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final dId in region.dhatuIds)
                  GestureDetector(
                    onTap: () => _tapDhatu(dId),
                    child: _buildDhatuPill(
                        _kDhatuMap[dId]!, _isDhatuHighlighted(dId)),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final sId in region.setIds)
                  GestureDetector(
                    onTap: () => _tapSet(sId),
                    child:
                        _buildSetPill(_kSetMap[sId]!, _isSetHighlighted(sId)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSkandhaLabel(String text) {
  var t = text.toLowerCase().trim();
  if (t.startsWith('the ')) t = t.substring(4);
  if (t.startsWith('aggregate of ')) t = t.substring(13);
  // Normalize plurals: "forms" → "form"
  const bases = {
    'form',
    'sensation',
    'perceptions',
    'formations',
    'consciousness'
  };
  if (bases.contains(t) || t == 'forms') return true;
  if (t == 'five aggregates') return true;
  return false;
}

/// Colour tints that distinguish dhatu categories while keeping badge
/// shape and size identical for consistent spacing.
///   • Faculties – yellow
///   • Objects   – orange
///   • Consciousnesses – white
enum _TriadCategory {
  faculties(
    background: Color(0xFFFFF9C4),
    border: Color(0xFFC8A830),
    icon: Color(0xFF7A6000),
  ),
  objects(
    background: Color(0xFFFFE6C0),
    border: Color(0xFFCC8838),
    icon: Color(0xFF96490A),
  ),
  consciousnesses(
    background: Color(0xFFFFFFFF),
    border: Color(0xFFD4C0A4),
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
