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

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              children: [
                _ChapterIntroCard(chapter: chapter),
                const SizedBox(height: 12),
                ...chapter.topics.map((topic) => _GatewayTopicCard(topic: topic)),
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

  final GatewayRichChapter chapter;

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
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ) ??
                      const TextStyle(
                        fontFamily: 'Crimson Text',
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${chapter.topics.length} sections',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedBrown,
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

class _GatewayTopicCard extends StatelessWidget {
  const _GatewayTopicCard({required this.topic});

  final GatewayRichTopic topic;

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
          _TriadCards(
            columns: [
              ('Faculties', blocks[i].items),
              ('Objects', blocks[i + 1].items),
              ('Consciousnesses', blocks[i + 2].items),
            ],
          ),
        );
        i += 2;
        continue;
      }
      if (block.type == 'ul' &&
          block.styleClass == 'duality-list' &&
          i + 1 < blocks.length &&
          blocks[i + 1].type == 'ul' &&
          blocks[i + 1].styleClass == 'duality-list') {
        children.add(
          _TriadCards(
            columns: [
              ('Inner Sources', blocks[i].items),
              ('Outer Sources', blocks[i + 1].items),
            ],
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
        children.add(_GatewayChipWrap(items: chipTexts));
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
                _IconBadge(icon: _iconForLabel(topic.title), size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ) ??
                        const TextStyle(
                          fontFamily: 'Crimson Text',
                          fontSize: 22,
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
                      ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            block.text ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
        );
      case 'ul':
      case 'ol':
        final isNumbered = block.type == 'ol';
        final items = block.items;
        if (block.styleClass == 'icon-list-grid' || block.styleClass == 'links-grid') {
          return Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    constraints: const BoxConstraints(minWidth: 180, maxWidth: 330),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
                              border: Border.all(color: const Color(0xFFDAC8AD)),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.bodyText,
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
        if (block.styleClass == 'split-list' && isNumbered && items.length > 8) {
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
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.bodyText,
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
  const _GatewayChipWrap({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE7DAC7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconBadge(icon: _iconForLabel(item), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.bodyText,
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

class _TriadCards extends StatelessWidget {
  const _TriadCards({required this.columns});

  final List<(String title, List<String> items)> columns;

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
                    child: _TriadCard(title: column.$1, items: column.$2),
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
                    padding: EdgeInsets.only(right: i == columns.length - 1 ? 0 : 8),
                    child: _TriadCard(title: columns[i].$1, items: columns[i].$2),
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
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
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
              _IconBadge(icon: _iconForLabel(title), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(icon: _iconForLabel(item), size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.bodyText,
                          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNumbered)
                  Text(
                    '${startIndex + i}. ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedBrown,
                          fontWeight: FontWeight.w600,
                        ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _IconBadge(icon: _iconForLabel(items[i]), size: 12),
                  ),
                if (!isNumbered) const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    items[i],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.bodyText,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.size,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 10,
      height: size + 10,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((size + 10) / 3),
        border: Border.all(color: const Color(0xFFE6D8C3)),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size,
        color: AppColors.primary,
      ),
    );
  }
}

IconData _iconForLabel(String text) {
  final t = text.toLowerCase();
  if (t.contains('eye') || t.contains('visual')) return Icons.visibility_outlined;
  if (t.contains('ear') || t.contains('sound')) return Icons.hearing_outlined;
  if (t.contains('nose') || t.contains('smell')) return Icons.air_outlined;
  if (t.contains('tongue') || t.contains('taste')) return Icons.water_drop_outlined;
  if (t.contains('body') || t.contains('texture') || t.contains('touch')) {
    return Icons.pan_tool_outlined;
  }
  if (t.contains('mind') || t.contains('conscious')) return Icons.psychology_outlined;
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
  if (t.contains('table') || t.contains('reference')) return Icons.table_chart_outlined;
  if (t.contains('link') || t.contains('dependent')) return Icons.link_outlined;
  if (t.contains('list') || t.contains('aggregate')) return Icons.format_list_bulleted;
  return Icons.circle_outlined;
}
