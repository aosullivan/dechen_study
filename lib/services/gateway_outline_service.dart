class GatewayOutlineSection {
  const GatewayOutlineSection({
    required this.path,
    required this.title,
    required this.depth,
  });

  final String path;
  final String title;
  final int depth;
}

class GatewayOutlineChapter {
  const GatewayOutlineChapter({
    required this.number,
    required this.title,
    required this.sections,
  });

  final int number;
  final String title;
  final List<GatewayOutlineSection> sections;
}

class GatewayOutlineService {
  GatewayOutlineService._();

  static final GatewayOutlineService instance = GatewayOutlineService._();

  // Source: the original gateway-to-knowledge.html content in this repo.
  static const List<GatewayOutlineChapter> _chapters = <GatewayOutlineChapter>[
    GatewayOutlineChapter(
      number: 1,
      title: 'The Aggregates',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(path: '1.1', title: 'Five Aggregates', depth: 0),
        GatewayOutlineSection(
            path: '1.2', title: 'Aggregate of Form', depth: 0),
        GatewayOutlineSection(
            path: '1.3', title: 'Aggregate of Sensation', depth: 0),
        GatewayOutlineSection(
            path: '1.4', title: 'Aggregate of Perception', depth: 0),
        GatewayOutlineSection(
            path: '1.5', title: 'Aggregate of Formation', depth: 0),
        GatewayOutlineSection(
            path: '1.6', title: 'Non-current Formations', depth: 0),
        GatewayOutlineSection(
            path: '1.7', title: 'Aggregate of Consciousness', depth: 0),
      ],
    ),
    GatewayOutlineChapter(
      number: 2,
      title: 'The Elements',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(
            path: '2.1', title: 'Eighteen Dhatus', depth: 0),
        GatewayOutlineSection(
            path: '2.2', title: 'Mental Object Sources (Ayatana)', depth: 0),
        GatewayOutlineSection(
            path: '2.3', title: 'Six Elements of a Person', depth: 0),
        GatewayOutlineSection(
            path: '2.4', title: 'Element Classifications', depth: 0),
        GatewayOutlineSection(
            path: '2.5', title: 'Classification Overlaps', depth: 0),
      ],
    ),
    GatewayOutlineChapter(
      number: 3,
      title: 'The Sense Sources',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(
            path: '3.1',
            title: 'Inner and Outer Sources',
            depth: 0),
        GatewayOutlineSection(
            path: '3.2',
            title: 'Mapping Ayatanas to Dhatus',
            depth: 0),
        GatewayOutlineSection(
            path: '3.3', title: 'The Five Base Knowables', depth: 0),
      ],
    ),
    GatewayOutlineChapter(
      number: 4,
      title: 'Dependent Origination',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(
            path: '4.1', title: 'Seven Related Causes', depth: 0),
        GatewayOutlineSection(
            path: '4.2', title: 'Six Related Conditions', depth: 0),
        GatewayOutlineSection(
            path: '4.3',
            title: 'Twelve Links of Dependent Origination',
            depth: 0),
        GatewayOutlineSection(
            path: '4.4',
            title: 'First Subdivision of the Twelve Links',
            depth: 0),
        GatewayOutlineSection(
            path: '4.5',
            title: 'Second Subdivision of the Twelve Links',
            depth: 0),
        GatewayOutlineSection(
            path: '4.6',
            title: 'Third Subdivision of the Twelve Links',
            depth: 0),
        GatewayOutlineSection(
            path: '4.7',
            title: 'Fourth Subdivision of the Twelve Links',
            depth: 0),
      ],
    ),
  ];

  Future<List<GatewayOutlineChapter>> getChapters() async {
    return _chapters;
  }

  Future<GatewayOutlineChapter?> getChapter(int chapterNumber) async {
    for (final chapter in _chapters) {
      if (chapter.number == chapterNumber) return chapter;
    }
    return null;
  }
}
